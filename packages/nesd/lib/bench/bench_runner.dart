import 'dart:convert';
import 'dart:io';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// `NesDatabase`'s default constructor loads an asset bundle XML; the
/// bench never needs database entries (standard iNES headers suffice),
/// so this stub keeps the measurement path free of asset IO.
class _BenchDatabase implements NesDatabase {
  const _BenchDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

class BenchResult {
  const BenchResult({
    required this.rom,
    required this.frames,
    required this.medianUs,
    required this.p90Us,
    required this.flatoutFps,
  });

  final String rom;
  final int frames;
  final int medianUs;
  final int p90Us;
  final double flatoutFps;

  String get logLine =>
      'NESD_BENCH rom=$rom frames=$frames median_us=$medianUs '
      'p90_us=$p90Us flatout_fps=${flatoutFps.toStringAsFixed(1)}';
}

Future<BenchResult?> maybeRunBench() async {
  final Directory base;

  try {
    base = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationSupportDirectory();
  } on Object {
    return null;
  }

  /// Marker file (JSON: {"rom": "`<name in bench dir>`", "frames": N})
  /// pushed via adb into the app's external files dir under bench/.
  /// Deleted before the run so a crash cannot loop the bench.
  final marker = File(p.join(base.path, 'bench', 'bench.json'));

  if (!marker.existsSync()) {
    return null;
  }

  final content = marker.readAsStringSync();

  marker.deleteSync();

  final Map<String, dynamic> config;

  try {
    config = jsonDecode(content) as Map<String, dynamic>;
  } on Object {
    return null;
  }

  final romName = config['rom'] as String;
  final frames = (config['frames'] as num?)?.toInt() ?? 3000;
  final romPath = p.join(base.path, 'bench', romName);

  return runBench(romPath: romPath, frames: frames, warmupFrames: 60);
}

/// Steps a directly-constructed NES synchronously (no isolate, no audio device,
/// no pacing, rewind off, no cheats) and times each frame.
BenchResult runBench({
  required String romPath,
  required int frames,
  required int warmupFrames,
}) {
  final bytes = File(romPath).readAsBytesSync();
  const factory = CartridgeFactory(database: _BenchDatabase());

  final cartridge = factory.fromFile(
    FilesystemFile(
      path: romPath,
      name: p.basename(romPath),
      type: FilesystemFileType.file,
    ),
    bytes,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus())..reset();

  void runFrame() {
    final target = nes.ppu.frames + 1;

    while (nes.ppu.frames < target) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }
  }

  for (var i = 0; i < warmupFrames; i++) {
    runFrame();
  }

  final frameTimesUs = List<int>.filled(frames, 0);
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < frames; i++) {
    final before = stopwatch.elapsedMicroseconds;

    runFrame();

    frameTimesUs[i] = stopwatch.elapsedMicroseconds - before;
  }

  final totalUs = stopwatch.elapsedMicroseconds;

  frameTimesUs.sort();

  return BenchResult(
    rom: p.basename(romPath),
    frames: frames,
    medianUs: frameTimesUs[frames ~/ 2],
    p90Us: frameTimesUs[(frames * 9) ~/ 10],
    flatoutFps: frames * 1e6 / totalUs,
  );
}
