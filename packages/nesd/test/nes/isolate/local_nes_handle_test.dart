import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/nes/isolate/local_nes_handle.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main() {
  test('loads a ROM and emits frames on the current isolate', () async {
    final handle = LocalNesHandle(
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    );

    final events = <NesIsolateEvent>[];
    final subscription = handle.events.listen(events.add);

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    handle.send(
      LoadRomCommand(
        rom: NesBytes.fromList([rom]),
        file: const FilesystemFile(
          path: 'nestest.nes',
          name: 'nestest.nes',
          type: FilesystemFileType.file,
        ),
        databaseEntry: null,
        region: null,
        rewindEnabled: false,
        cheats: const [],
        breakpoints: const [],
      ),
    );

    await handle.events
        .firstWhere((event) => event is RomLoadedEvent)
        .timeout(const Duration(seconds: 10));

    await handle.events
        .firstWhere((event) => event is FrameEvent)
        .timeout(const Duration(seconds: 10));

    await handle.dispose();
    await subscription.cancel();

    expect(events.whereType<RomLoadedEvent>(), isNotEmpty);
    expect(events.whereType<ErrorEvent>(), isEmpty);
  });

  test('command errors surface as ErrorEvents, not crashes', () async {
    final handle = LocalNesHandle(
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    )..send(_badRomCommand());

    final failure = await handle.events
        .firstWhere(
          (event) => event is RomLoadFailedEvent || event is ErrorEvent,
        )
        .timeout(const Duration(seconds: 5));

    expect(failure, isA<RomLoadFailedEvent>());

    await handle.dispose();
  });

  test('the queue keeps handling commands after a failed one', () async {
    final handle = LocalNesHandle(
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    )..send(_badRomCommand());

    await handle.events
        .firstWhere(
          (event) => event is RomLoadFailedEvent || event is ErrorEvent,
        )
        .timeout(const Duration(seconds: 5));

    // A later command must still be handled: StopCommand always answers
    // with a StoppedEvent.
    handle.send(const StopCommand());

    final stopped = await handle.events
        .firstWhere((event) => event is StoppedEvent)
        .timeout(const Duration(seconds: 5));

    expect(stopped, isA<StoppedEvent>());

    await handle.dispose();
  });

  test('send after dispose is a silent no-op', () async {
    final handle = LocalNesHandle(
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    );

    await handle.dispose();

    expect(() => handle.send(const StopCommand()), returnsNormally);
  });

  test('events are buffered while no listener is attached', () async {
    final handle = LocalNesHandle(
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    )..send(const StopCommand());

    // Give the queue a chance to emit before anyone listens.
    await pumpEventQueue();

    final stopped = await handle.events
        .firstWhere((event) => event is StoppedEvent)
        .timeout(const Duration(seconds: 5));

    expect(stopped, isA<StoppedEvent>());

    await handle.dispose();
  });
}

NesCommand _badRomCommand() => LoadRomCommand(
  rom: NesBytes.fromList([
    Uint8List.fromList([0, 1, 2]), // not a valid iNES header
  ]),
  file: const FilesystemFile(
    path: 'bad.nes',
    name: 'bad.nes',
    type: FilesystemFileType.file,
  ),
  databaseEntry: null,
  region: null,
  rewindEnabled: false,
  cheats: const [],
  breakpoints: const [],
);
