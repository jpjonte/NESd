// Portable runner: executes the headless bench multiple times,
// computes median, and writes CSV/JSONL artifacts.
// Usage:
//   dart run bin/perf/run.dart --rom path --frames 200 --warmup 50 --runs 9

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final rom = opts['rom'];

  if (rom == null) {
    stderr.writeln('Missing --rom <path>');
    exit(2);
  }

  final frames = int.tryParse(opts['frames'] ?? '') ?? 200;
  final warmup = int.tryParse(opts['warmup'] ?? '') ?? 50;
  final runs = int.tryParse(opts['runs'] ?? '') ?? 9;
  final label = opts['label'];

  final results = <Map<String, dynamic>>[];

  for (var i = 0; i < runs; i++) {
    final line = await _bench(rom, frames, warmup, label);
    results.add(jsonDecode(line) as Map<String, dynamic>);
  }

  results.sort((a, b) => (a['fps'] as num).compareTo(b['fps'] as num));
  final median = results[results.length ~/ 2];

  const jsonlPath = 'bin/perf/results/results.jsonl';
  await Directory('bin/perf/results').create(recursive: true);

  await File(jsonlPath).writeAsString(
    '${results.map(jsonEncode).join('\n')}\n',
    mode: FileMode.append,
  );

  final countMsg = 'Appended ${results.length} runs to $jsonlPath;';
  final medianMsg = ' median fps=${median['fps']}';
  stdout.writeln('$countMsg$medianMsg');
}

Future<String> _bench(String rom, int frames, int warmup, String? label) async {
  final res = await Process.run(Platform.resolvedExecutable, [
    'run',
    'bin/perf/bench.dart',
    '--rom',
    rom,
    '--frames',
    '$frames',
    '--warmup',
    '$warmup',
    if (label != null) ...['--label', label],
  ]);

  if (res.exitCode != 0) {
    stderr.writeln(res.stderr);
    exit(res.exitCode);
  }

  return (res.stdout as String).trim();
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

// no default mode; execution mode is controlled by how Dart/Flutter runs the tool
