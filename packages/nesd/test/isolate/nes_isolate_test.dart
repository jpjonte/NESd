import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/rewind/rewind_codec.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd_audio/nesd_audio.dart';

void main() {
  test('spawn, load rom, receive frames, release, dispose', () async {
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: rewindCodecLibraryPath,
      audioLibraryPath: NesdAudio.libraryPath,
      disableAudio: true, // null device: no audio hardware in tests
    );

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    isolate.send(
      LoadRomCommand(
        rom: NesBytes.fromList([rom]),
        file: const FilesystemFile(
          path: 'nestest.nes',
          name: 'nestest.nes',
          type: FilesystemFileType.file,
        ),
        databaseEntry: null,
        region: null,
        rewindEnabled: true, // exercises rewind + LZ4 inside the isolate
        cheats: const [],
        breakpoints: const [],
      ),
    );

    await isolate.events
        .firstWhere((e) => e is RomLoadedEvent)
        .timeout(const Duration(seconds: 10));

    final frames = await isolate.events
        .where((e) => e is FrameEvent)
        .cast<FrameEvent>()
        .take(5)
        .toList()
        .timeout(const Duration(seconds: 10));

    for (final frame in frames) {
      expect(frame.frameHandle, isNonZero);
      expect(frame.width, 256);
      expect(frame.height, 240);

      isolate.send(ReleaseFrameCommand(frameHandle: frame.frameHandle));
    }

    await isolate.dispose();
  });

  test('an uncaught worker error separates the stack trace from the '
      'message', () async {
    // Reproduces #234: a missing LZ4 library makes the first rewind
    // snapshot throw outside the command queue, surfacing through the
    // isolate's error port.
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: '/nonexistent/eslz4.so',
      audioLibraryPath: NesdAudio.libraryPath,
      disableAudio: true, // null device: no audio hardware in tests
    );

    addTearDown(isolate.dispose);

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    isolate.send(
      LoadRomCommand(
        rom: NesBytes.fromList([rom]),
        file: const FilesystemFile(
          path: 'nestest.nes',
          name: 'nestest.nes',
          type: FilesystemFileType.file,
        ),
        databaseEntry: null,
        region: null,
        rewindEnabled: true,
        cheats: const [],
        breakpoints: const [],
      ),
    );

    final event =
        await isolate.events
                .firstWhere((e) => e is ErrorEvent)
                .timeout(const Duration(seconds: 10))
            as ErrorEvent;

    expect(event.message, isNot(contains('\n#')));
    expect(event.stackTrace, contains('#0'));
  });

  test('garbage LoadSramCommand keeps the isolate alive and framing', () async {
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: rewindCodecLibraryPath,
      audioLibraryPath: NesdAudio.libraryPath,
      disableAudio: true, // null device: no audio hardware in tests
    );

    addTearDown(isolate.dispose);

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    isolate.send(
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

    await isolate.events
        .firstWhere((e) => e is RomLoadedEvent)
        .timeout(const Duration(seconds: 10));

    // Feed obviously-wrong SRAM. nestest has no battery so cartridge.load
    // is a no-op (the guard's ErrorEvent branch is unreachable here), but
    // the command must not wedge the serialized queue or kill the loop.
    isolate.send(LoadSramCommand(sram: NesBytes.fromList([Uint8List(3)])));

    final frames = await isolate.events
        .where((e) => e is FrameEvent)
        .cast<FrameEvent>()
        .take(3)
        .toList()
        .timeout(const Duration(seconds: 10));

    for (final frame in frames) {
      isolate.send(ReleaseFrameCommand(frameHandle: frame.frameHandle));
    }

    expect(frames, hasLength(3));
  });

  test(
    'events buffers messages emitted during a zero-listener window',
    () async {
      final isolate = await NesIsolate.spawn(
        lz4LibraryPath: rewindCodecLibraryPath,
        audioLibraryPath: NesdAudio.libraryPath,
        disableAudio: true, // null device: no audio hardware in tests
      );

      addTearDown(isolate.dispose);

      // By the time spawn() returns, the handshake's `firstWhere` has
      // already fired and cancelled its subscription, so `events` has
      // zero listeners here.
      isolate.send(
        LoadRomCommand(
          rom: NesBytes.fromList([Uint8List(16)]),
          file: const FilesystemFile(
            path: 'invalid.nes',
            name: 'invalid.nes',
            type: FilesystemFileType.file,
          ),
          databaseEntry: null,
          region: null,
          rewindEnabled: false,
          cheats: const [],
          breakpoints: const [],
        ),
      );

      // Give the worker time to process the command and emit
      // RomLoadFailedEvent while nobody is listening on `events`.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final event = await isolate.events
          .firstWhere((e) => e is RomLoadFailedEvent)
          .timeout(const Duration(seconds: 5));

      expect(event, isA<RomLoadFailedEvent>());
    },
  );
}
