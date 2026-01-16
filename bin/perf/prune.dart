// Maintains perf results in bin/perf/results/results.jsonl
//
// Features:
// - List unique commit identifiers present in the results file.
// - Delete all entries for one or more commits (non-interactive or
//   interactive selection).
//
// Usage examples:
//   dart run bin/perf/prune.dart --list
//   dart run bin/perf/prune.dart --delete <commit> [--delete <commit> ...]
//   dart run bin/perf/prune.dart  # interactive selection
//   dart run bin/perf/prune.dart --jsonl path/to/results.jsonl

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final opts = _args(args);

  final path = opts['jsonl'] ?? 'bin/perf/results/results.jsonl';
  final file = File(path);

  if (!file.existsSync()) {
    stderr.writeln('Results file not found: $path');
    exit(2);
  }

  final lines = await file.readAsLines();
  final records = <Map<String, dynamic>>[];

  for (final line in lines) {
    final s = line.trim();
    if (s.isEmpty) {
      continue;
    }
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      if (m.containsKey('commit')) {
        records.add(m);
      }
    } on Object {
      // skip malformed lines silently
    }
  }

  if (records.isEmpty) {
    stdout.writeln('No records found in $path');
    return;
  }

  final commits = _uniqueCommitsInOrder(records);

  if (opts.containsKey('list')) {
    _printCommitList(commits, records);
    return;
  }

  final deletes = <String>{};

  final provided = opts['delete'];
  if (provided != null) {
    deletes.addAll(optsAll('delete', args));
  } else {
    // Interactive selection
    _printCommitList(commits, records);
    stdout
      ..writeln()
      ..writeln(
        'Enter indices (e.g. 1,3-5) or commit ids to delete.'
        ' Empty to abort.',
      )
      ..write('> ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty) {
      stdout.writeln('Aborted.');
      return;
    }
    final parsed = _parseSelection(input, commits);
    if (parsed.isEmpty) {
      stdout.writeln('No matches. Aborted.');
      return;
    }
    deletes.addAll(parsed);
  }

  final before = records.length;
  final filtered = records
      .where((r) => !deletes.contains(r['commit'] as String))
      .toList();
  final removed = before - filtered.length;

  if (removed == 0) {
    stdout.writeln('Nothing to delete.');
    return;
  }

  stdout.writeln(
    'About to delete $removed entries for ${deletes.length} commit(s).',
  );

  if (!opts.containsKey('yes')) {
    stdout.write('Proceed? [y/N] ');
    final ans = (stdin.readLineSync() ?? '').trim().toLowerCase();
    if (ans != 'y' && ans != 'yes') {
      stdout.writeln('Aborted.');
      return;
    }
  }

  final backup = File('$path.bak');
  await backup.writeAsString(lines.join('\n'));

  final sink = file.openWrite();
  for (final r in filtered) {
    sink.writeln(jsonEncode(r));
  }
  await sink.close();

  stdout.writeln(
    'Done. Wrote ${filtered.length} lines. Backup at ${backup.path}.',
  );
}

List<String> _uniqueCommitsInOrder(List<Map<String, dynamic>> records) {
  final seen = <String>{};
  final order = <String>[];
  for (final r in records) {
    final c = r['commit'] as String?;
    if (c == null) {
      continue;
    }
    if (seen.add(c)) {
      order.add(c);
    }
  }
  return order;
}

void _printCommitList(
  List<String> commits,
  List<Map<String, dynamic>> records,
) {
  final counts = <String, int>{};
  for (final r in records) {
    final c = r['commit'] as String?;
    if (c != null) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
  }

  for (var i = 0; i < commits.length; i++) {
    final c = commits[i];
    final n = counts[c] ?? 0;
    stdout.writeln('${i + 1}. $c ($n entries)');
  }
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

// Returns all values for a repeated option key, e.g. --delete a --delete b.
List<String> optsAll(String key, List<String> args) {
  final k = '--$key';
  final vals = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == k) {
      final n = i + 1 < args.length ? args[i + 1] : null;
      if (n != null && !n.startsWith('--')) {
        vals.add(n);
        i++;
      }
    }
  }
  return vals;
}

// Parse a selection string like "1,3-5,abcdef" where indices refer to the
// enumerated commit list and other tokens are treated as commit ids.
Set<String> _parseSelection(String input, List<String> commits) {
  final out = <String>{};
  final parts = input
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);

  for (final p in parts) {
    final dash = p.indexOf('-');
    if (dash > 0 && dash < p.length - 1) {
      final a = int.tryParse(p.substring(0, dash));
      final b = int.tryParse(p.substring(dash + 1));
      if (a != null && b != null) {
        final lo = a < b ? a : b;
        final hi = a < b ? b : a;
        for (var i = lo; i <= hi; i++) {
          final idx = i - 1;
          if (idx >= 0 && idx < commits.length) {
            out.add(commits[idx]);
          }
        }
        continue;
      }
    }

    final n = int.tryParse(p);
    if (n != null) {
      final idx = n - 1;
      if (idx >= 0 && idx < commits.length) {
        out.add(commits[idx]);
      }
      continue;
    }

    // treat as commit id token
    out.add(p);
  }
  return out;
}
