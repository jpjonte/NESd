import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../helpers/synthetic_rom.dart';

void main() {
  test('worker loads a synthetic ROM through the production path', () async {
    final events = <NesIsolateEvent>[];
    final worker = NesWorker(
      send: events.add,
      audioFactory: () => defaultNesdAudio(nullDevice: true),
    );

    await worker.handleCommand(
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

    final failures = events.whereType<RomLoadFailedEvent>().toList();

    expect(
      failures,
      isEmpty,
      reason: failures.isEmpty ? '' : 'load failed: ${failures.first.message}',
    );
    expect(events.whereType<RomLoadedEvent>(), isNotEmpty);

    await worker.shutdown();
  });
}
