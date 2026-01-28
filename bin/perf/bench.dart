// Headless performance benchmark for NESd core.
// Usage:
//   dart run bin/perf/bench.dart --rom path/to.rom \
//     [--frames 200] [--warmup 50]

import 'dart:convert';
import 'dart:io';

import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main(List<String> args) async {
  final opts = _parseArgs(args);

  final romPath = opts['rom'];
  if (romPath == null) {
    stderr.writeln('Missing --rom <path>');
    exitCode = 2;
    return;
  }

  final warmup = int.tryParse(opts['warmup'] ?? '') ?? 50;
  final frames = int.tryParse(opts['frames'] ?? '') ?? 200;
  final label = opts['label'];

  final bytes = await File(romPath).readAsBytes();

  final factory = CartridgeFactory(database: _NullNesDatabase());
  final file = FilesystemFile(
    path: romPath,
    name: romPath,
    type: FilesystemFileType.file,
  );

  final cart = factory.fromFile(file, bytes);

  final nes = NES(cartridge: cart, eventBus: EventBus());

  // Avoid NES.reset() to keep the async run loop off.
  nes.bus.cartridge.reset();
  nes.cpu.reset();
  nes.apu.reset();
  nes.ppu.reset();

  _runFrames(nes, warmup);

  final sw = Stopwatch()..start();
  _runFrames(nes, frames);
  sw.stop();

  final ms = sw.elapsedMilliseconds;
  final fps = frames * 1000.0 / (ms == 0 ? 1 : ms);

  final commit = await _gitDescribeDirty();
  final platform =
      '${Platform.operatingSystem}-${Platform.version.split(' ').first}';
  final ts = DateTime.now().toUtc().toIso8601String();

  final out = {
    'commit': commit.trim(),
    'ts': ts,
    'platform': platform,
    'rom':
        label ??
        (File(romPath).uri.pathSegments.isNotEmpty
            ? File(romPath).uri.pathSegments.last
            : romPath),
    'warmup': warmup,
    'frames': frames,
    'duration_ms': ms,
    'fps': double.parse(fps.toStringAsFixed(2)),
  };

  stdout.writeln(jsonEncode(out));
}

void _runFrames(NES nes, int count) {
  if (count <= 0) {
    return;
  }

  final start = nes.ppu.frames;
  final target = start + count;
  while (nes.ppu.frames < target) {
    nes.step();
    // Keep audio buffer bounded to avoid incidental overhead.
    nes.apu.sampleIndex = 0;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      final key = a.substring(2);
      final next = i + 1 < args.length ? args[i + 1] : null;
      if (next != null && !next.startsWith('--')) {
        map[key] = next;
        i++;
      } else {
        map[key] = 'true';
      }
    }
  }
  return map;
}

Future<String> _gitDescribeDirty() async {
  // If clean, prefer a stable description without dirty suffix.
  try {
    final st = await Process.run('git', ['status', '--porcelain']);
    final dirty = st.exitCode == 0 && (st.stdout as String).trim().isNotEmpty;

    final base = await Process.run('git', ['describe', '--always']);
    if (base.exitCode != 0) {
      return '';
    }

    final tag = (base.stdout as String).trim();

    if (!dirty) {
      return tag; // clean tree
    }

    final diffHash = await _gitDiffHash();
    final short = diffHash.length > 7 ? diffHash.substring(0, 7) : diffHash;
    return '$tag-dirty-$short';
  } on Object catch (_) {}

  return '';
}

Future<String> _gitDiffHash() async {
  try {
    final pipe = await Process.run('bash', [
      '-lc',
      'git diff --no-ext-diff | git hash-object --stdin || true',
    ]);
    if (pipe.exitCode == 0) {
      final out = (pipe.stdout as String).trim();
      if (out.isNotEmpty) {
        return out;
      }
    }

    final pipe2 = await Process.run('bash', [
      '-lc',
      'git status --porcelain | git hash-object --stdin || true',
    ]);
    if (pipe2.exitCode == 0) {
      final out = (pipe2.stdout as String).trim();
      if (out.isNotEmpty) {
        return out;
      }
    }
  } on Object catch (_) {}

  return '';
}

class _NullNesDatabase implements NesDatabase {
  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}
