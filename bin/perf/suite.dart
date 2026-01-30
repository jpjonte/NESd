// Runs the perf suite defined in bin/perf/suite.json
// and appends median results to perf/results.csv and runs to jsonl.
// Usage:
//   dart run bin/perf/suite.dart [--config bin/perf/suite.json]

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final opts = _args(args);
  final path = opts['config'] ?? 'bin/perf/suite.json';

  final cfgFile = File(path);

  if (!cfgFile.existsSync()) {
    stderr.writeln('Config not found: $path');
    exit(2);
  }

  final cfg = jsonDecode(await cfgFile.readAsString()) as Map<String, dynamic>;
  final def = cfg['defaults'] as Map<String, dynamic>? ?? {};
  final frames = (def['frames'] as num?)?.toInt() ?? 300;
  final warmup = (def['warmup'] as num?)?.toInt() ?? 60;
  final runs = (def['runs'] as num?)?.toInt() ?? 9;

  final items = (cfg['items'] as List<dynamic>?) ?? const [];
  if (items.isEmpty) {
    stderr.writeln('No items in suite.');
    exit(3);
  }

  for (final raw in items) {
    final it = raw as Map<String, dynamic>;
    final rom = it['rom'] as String;
    final label = it['label'] as String?;
    final f = (it['frames'] as num?)?.toInt() ?? frames;
    final w = (it['warmup'] as num?)?.toInt() ?? warmup;
    final r = (it['runs'] as num?)?.toInt() ?? runs;

    stdout.writeln('Running: ${label ?? rom}');
    await _runOne(rom, f, w, r, label);
  }

  stdout.writeln('Suite complete. See perf/results jsonl');
}

Future<void> _runOne(
  String rom,
  int frames,
  int warmup,
  int runs,
  String? label,
) async {
  final res = await Process.run(Platform.resolvedExecutable, [
    'run',
    'bin/perf/run.dart',
    '--rom',
    rom,
    '--frames',
    '$frames',
    '--warmup',
    '$warmup',
    '--runs',
    '$runs',
    if (label != null) ...['--label', label],
  ]);
  if (res.exitCode != 0) {
    stderr.writeln(res.stderr);
    exit(res.exitCode);
  }
  stdout.write(res.stdout);
}

Map<String, String> _args(List<String> a) {
  final m = <String, String>{};
  for (var i = 0; i < a.length; i++) {
    final s = a[i];
    if (s.startsWith('--')) {
      final k = s.substring(2);
      final n = i + 1 < a.length ? a[i + 1] : null;
      if (n != null && !n.startsWith('--')) {
        m[k] = n;
        i++;
      } else {
        m[k] = 'true';
      }
    }
  }
  return m;
}

// no execution mode parameter; run with Flutter test or dart as desired
