// Perf suite runner under flutter_test to ensure dart:ui availability.
// Run:
//   fvm flutter test -t perf bin/perf/bench_test.dart

import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;

void main() {
  test('perf_suite', timeout: Timeout.none, () async {
    final cfg = await _loadConfig(_workspacePath('bin/perf/suite.json'));
    final def = (cfg['defaults'] as Map<String, dynamic>?) ?? {};
    final frames = (def['frames'] as num?)?.toInt() ?? 300;
    final warmup = (def['warmup'] as num?)?.toInt() ?? 60;
    final runs = (def['runs'] as num?)?.toInt() ?? 9;

    for (final raw in (cfg['items'] as List)) {
      final it = raw as Map<String, dynamic>;
      final romPath = it['rom'] as String;
      final label = it['label'] as String? ?? romPath;
      final f = (it['frames'] as num?)?.toInt() ?? frames;
      final w = (it['warmup'] as num?)?.toInt() ?? warmup;
      final r = (it['runs'] as num?)?.toInt() ?? runs;

      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < r; i++) {
        results.add(await _runOne('../../$romPath', f, w, label));
      }

      results.sort((a, b) => (a['fps'] as num).compareTo(b['fps'] as num));

      await Directory(
        _workspacePath('bin/perf/results'),
      ).create(recursive: true);

      // append runs to JSONL only (one consolidated artifact)
      File(_workspacePath('bin/perf/results/results.jsonl')).writeAsStringSync(
        '${results.map(jsonEncode).join('\n')}\n',
        mode: FileMode.append,
      );
    }
  });
}

Future<Map<String, dynamic>> _loadConfig(String path) async {
  final file = File(path);
  final data = await file.readAsString();
  return jsonDecode(data) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _runOne(
  String romPath,
  int frames,
  int warmup,
  String label,
) async {
  final bytes = await File(romPath).readAsBytes();
  final factory = CartridgeFactory(database: _NullDb());
  final file = FilesystemFile(
    path: romPath,
    name: romPath,
    type: FilesystemFileType.file,
  );
  final cart = factory.fromFile(file, bytes)..databaseEntry = null;
  final nes = NES(cartridge: cart, eventBus: EventBus());

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

  return {
    'commit': commit.trim(),
    'ts': ts,
    'platform': platform,
    'rom': label,
    'warmup': warmup,
    'frames': frames,
    'duration_ms': ms,
    'fps': double.parse(fps.toStringAsFixed(2)),
  };
}

void _runFrames(NES nes, int count) {
  final start = nes.ppu.frames;
  final target = start + count;
  while (nes.ppu.frames < target) {
    nes.step();
    nes.apu.sampleIndex = 0;
  }
}

Future<String> _gitDescribeDirty() async {
  try {
    final st = await Process.run('git', ['status', '--porcelain']);
    final dirty = st.exitCode == 0 && (st.stdout as String).trim().isNotEmpty;

    final base = await Process.run('git', ['describe', '--always']);
    if (base.exitCode != 0) {
      return '';
    }

    final tag = (base.stdout as String).trim();

    if (!dirty) {
      return tag;
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

String _workspacePath(String relative) => p.join(_workspaceRoot, relative);

String get _workspaceRoot {
  final env = Platform.environment['NESD_WORKSPACE_ROOT'];
  if (env != null && env.isNotEmpty) {
    return env;
  }

  final cwd = Directory.current.path;
  if (Directory(p.join(cwd, 'packages', 'nesd')).existsSync()) {
    return cwd;
  }

  final parent = Directory.current.parent.path;
  if (Directory(p.join(parent, 'packages', 'nesd')).existsSync()) {
    return parent;
  }

  return cwd;
}

class _NullDb implements NesDatabase {
  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}
