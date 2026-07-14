import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:es_compression/lz4.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main() {
  test('spawn, load rom, receive frames, release, dispose', () async {
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: Lz4Codec.libraryPath,
      disableAudio: true, // flutter_tester has no miniaudio symbols
    );

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    isolate.send(
      LoadRomCommand(
        rom: TransferableTypedData.fromList([rom]),
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
      expect(frame.pointerAddress, isNonZero);
      expect(frame.width, 256);
      expect(frame.height, 240);

      isolate.send(ReleaseFrameCommand(pointerAddress: frame.pointerAddress));
    }

    await isolate.dispose();
  });

  test('garbage LoadSramCommand keeps the isolate alive and framing', () async {
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: Lz4Codec.libraryPath,
      disableAudio: true, // flutter_tester has no miniaudio symbols
    );

    addTearDown(isolate.dispose);

    final rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

    isolate.send(
      LoadRomCommand(
        rom: TransferableTypedData.fromList([rom]),
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
    isolate.send(
      LoadSramCommand(sram: TransferableTypedData.fromList([Uint8List(3)])),
    );

    final frames = await isolate.events
        .where((e) => e is FrameEvent)
        .cast<FrameEvent>()
        .take(3)
        .toList()
        .timeout(const Duration(seconds: 10));

    for (final frame in frames) {
      isolate.send(ReleaseFrameCommand(pointerAddress: frame.pointerAddress));
    }

    expect(frames, hasLength(3));
  });

  test(
    'events buffers messages emitted during a zero-listener window',
    () async {
      final isolate = await NesIsolate.spawn(
        lz4LibraryPath: Lz4Codec.libraryPath,
        disableAudio: true, // flutter_tester has no miniaudio symbols
      );

      addTearDown(isolate.dispose);

      // By the time spawn() returns, the handshake's `firstWhere` has
      // already fired and cancelled its subscription, so `events` has
      // zero listeners here.
      isolate.send(
        LoadRomCommand(
          rom: TransferableTypedData.fromList([Uint8List(16)]),
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
