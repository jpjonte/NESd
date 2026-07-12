import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _NullDatabase implements NesDatabase {
  const _NullDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

/// Records whether each sleepFor call received an audio probe value.
class _RecordingGovernor extends PacingGovernor {
  const _RecordingGovernor(this.audioArgs);

  final List<AudioBufferStatus?> audioArgs;

  @override
  Duration sleepFor({
    required int samplesProduced,
    required Duration elapsed,
    AudioBufferStatus? audio,
  }) {
    audioArgs.add(audio);

    return Duration.zero;
  }
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('rewind pop path paces against the audio fill probe', () async {
    final audioArgs = <AudioBufferStatus?>[];
    const path = '../../roms/test/nestest/nestest.nes';
    final bytes = File(path).readAsBytesSync();
    const factory = CartridgeFactory(database: _NullDatabase());
    final cartridge = factory.fromFile(
      const FilesystemFile(
        path: path,
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
      bytes,
    )..databaseEntry = null;

    final nes =
        NES(
            cartridge: cartridge,
            eventBus: EventBus(),
            governor: _RecordingGovernor(audioArgs),
            audioFillProbe: () => (fill: 1200, capacity: 2400),
          )
          ..reset()
          ..rewindEnabled = true
          ..rewindCaptureInterval = 4;

    unawaited(nes.run());

    await _waitUntil(() => audioArgs.length > 40);

    audioArgs.clear();
    nes.rewind = true;

    await _waitUntil(() => audioArgs.length > 10);

    nes
      ..rewind = false
      ..stop();

    await _waitUntil(() => !nes.inLoop);

    // Every governor call during rewind (pop and hold alike) must
    // carry the probe's value — no null gaps.
    // With rewindCaptureInterval=4, each pop is followed by 3 holds,
    // so >10 calls guarantees both pop and hold branches are exercised.
    expect(audioArgs, hasLength(greaterThan(10)));
    expect(audioArgs, everyElement((fill: 1200, capacity: 2400)));
  });
}
