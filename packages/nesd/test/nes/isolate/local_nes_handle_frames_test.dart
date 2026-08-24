import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/nes/isolate/local_nes_handle.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../helpers/synthetic_rom.dart';

/// Chrome-compatible (no dart:io)
void main() {
  test('frames carry the platform payload and round-trip release', () async {
    final handle =
        LocalNesHandle(audioFactory: () => defaultNesdAudio(nullDevice: true))
          ..send(
            LoadRomCommand(
              rom: NesBytes.fromList([syntheticNrom()]),
              file: const FilesystemFile(
                path: 'synthetic.nes',
                name: 'synthetic.nes',
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

    // The pool holds only a few buffers, so more frames than the pool size keep
    // arriving only if the releases reach the worker.
    for (var i = 0; i < 6; i++) {
      final frame =
          await handle.events
                  .firstWhere((event) => event is FrameEvent)
                  .timeout(const Duration(seconds: 10))
              as FrameEvent;

      if (kIsWeb) {
        expect(frame.pixels, isA<InlineFramePixels>());
        expect(
          (frame.pixels as InlineFramePixels).bytes,
          hasLength(frame.width * frame.height * 4),
        );
      } else {
        expect(frame.pixels, isA<PointerFramePixels>());
      }

      handle.send(ReleaseFrameCommand(frameHandle: frame.frameHandle));
    }

    await handle.dispose();
  });
}
