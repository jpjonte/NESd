// Simple plot generator: reads JSONL runs (one JSON object per line)
// from bin/perf/results/results.jsonl and writes perf/plot.html with
// inline SVG charts of FPS over commits, grouped by ROM.
// Usage:
//   dart run bin/perf/plot.dart [--jsonl bin/perf/results/results.jsonl] \
//     [--out bin/perf/results/plot.html]

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final opts = _args(args);
  final jsonlPath = opts['jsonl'] ?? 'bin/perf/results/results.jsonl';
  final outPath = opts['out'] ?? 'bin/perf/results/plot.html';
  final jf = File(jsonlPath);
  if (!jf.existsSync()) {
    stderr.writeln('JSONL not found: $jsonlPath');
    exit(2);
  }

  final lines = jf.readAsLinesSync();
  if (lines.isEmpty) {
    stderr.writeln('JSONL has no data rows.');
    exit(3);
  }

  final groups = <String, List<Record>>{};

  for (final line in lines) {
    if (line.trim().isEmpty) {
      continue;
    }

    final rec = Record.fromJson(line);

    groups.putIfAbsent(rec.rom, () => []).add(rec);
  }

  for (final list in groups.values) {
    list.sort((a, b) => a.ts.compareTo(b.ts));
  }

  final html = _renderHtml(groups);
  File(outPath).writeAsStringSync(html);
  stdout.writeln('Wrote $outPath');
}

class Record {
  Record({
    required this.commit,
    required this.ts,
    required this.rom,
    required this.fps,
  });

  final String commit;
  final DateTime ts;
  final String rom;
  final double fps;

  factory Record.fromJson(String line) {
    final m = jsonDecode(line) as Map<String, dynamic>;
    return Record(
      commit: m['commit'] as String,
      ts: DateTime.parse(m['ts'] as String),
      rom: m['rom'] as String,
      fps: (m['fps'] as num).toDouble(),
    );
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

class _Point {
  _Point({required this.commit, required this.ts, required this.fps});
  final String commit;
  final DateTime ts;
  final double fps;
}

List<_Point> _aggregateByCommit(List<Record> data) {
  // Group by commit, compute median FPS per commit, and keep earliest ts
  final byCommit = <String, List<Record>>{};
  for (final r in data) {
    (byCommit[r.commit] ??= []).add(r);
  }

  final points = <_Point>[];
  byCommit.forEach((commit, rows) {
    rows.sort((a, b) => a.fps.compareTo(b.fps));
    final median = rows[rows.length ~/ 2].fps;
    // choose earliest timestamp for ordering on x-axis
    final ts = rows.map((e) => e.ts).reduce((a, b) => a.isBefore(b) ? a : b);
    points.add(_Point(commit: commit, ts: ts, fps: median));
  });

  // Order points by timestamp to give a temporal left-to-right trend
  points.sort((a, b) => a.ts.compareTo(b.ts));
  return points;
}

String _renderHtml(Map<String, List<Record>> groups) {
  final buf = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<title>NESd Perf</title>')
    ..writeln('<style>')
    ..writeln(':root{')
    ..writeln('  --bg:#ffffff; --fg:#111111; --title:#333333;')
    ..writeln('  --axis:#444444; --grid:#eeeeee; --label:#666666;')
    ..writeln('}')
    ..writeln('@media (prefers-color-scheme: dark){:root{')
    ..writeln('  --bg:#0f1115; --fg:#e6e6e6; --title:#f0f0f0;')
    ..writeln('  --axis:#888888; --grid:#2a2f3a; --label:#bbbbbb;')
    ..writeln('}}')
    ..writeln('body{font:12px sans-serif;margin:16px;')
    ..writeln('  background:var(--bg); color:var(--fg);}')
    ..writeln('.chart{margin:12px 0;}')
    ..writeln('.title{margin:4px 0 2px 4px;color:var(--title);}')
    ..writeln('svg{background:transparent;}')
    ..writeln('.axis{stroke:var(--axis);stroke-width:1}')
    ..writeln('.grid{stroke:var(--grid);stroke-width:1}')
    ..writeln('text.ylabel{fill:var(--label);}')
    ..writeln('</style>');

  final colors = [
    '#1f77b4',
    '#ff7f0e',
    '#2ca02c',
    '#d62728',
    '#9467bd',
    '#8c564b',
    '#e377c2',
    '#7f7f7f',
  ];

  var ci = 0;

  groups.forEach((title, data) {
    // Aggregate per-commit medians for this group (rom)
    final series = _aggregateByCommit(data);

    const w = 1000;
    const h = 500;
    const pad = 48; // extra left pad to accommodate right-aligned labels

    final maxFps = series.map((e) => e.fps).reduce(_max);

    const tickDivisions = 4; // target 5 ticks

    const step = 10.0;

    var hi = step * tickDivisions;

    while (hi < maxFps) {
      hi += step;
    }

    final tickCount = (hi / step).round() + 1;

    final color = colors[ci % colors.length];

    ci++;

    buf
      ..writeln('<div class="chart">')
      ..writeln('<div class="title">$title</div>')
      ..writeln('<svg width="$w" height="$h">');

    // axes
    const ax = pad;
    const ay = h - pad;
    const rx = w - pad;
    const ty = pad;

    buf
      ..writeln('<line class="axis" x1="$ax" y1="$ay" x2="$rx" y2="$ay" />')
      ..writeln('<line class="axis" x1="$ax" y1="$ay" x2="$ax" y2="$ty" />');

    for (var i = 0; i < tickCount; i++) {
      final t = 0 + step * i;
      final y = _mapY(t, 0, hi, h, pad);

      buf
        ..writeln('<line class="grid" x1="$ax" y1="$y" x2="$rx" y2="$y" />')
        ..writeln(
          '<text class="ylabel" x="${ax - 8}" y="$y" '
          'text-anchor="end" dominant-baseline="middle">'
          '${t.toInt()}</text>',
        );
    }

    // lollipop series: vertical stems from x-axis to value + circle marker
    final n = series.length;
    final dx = (rx - ax) / (n + 1); // margin left and right

    for (var i = 0; i < n; i++) {
      final x = ax + dx * (i + 1);
      final y = _mapY(series[i].fps, 0, hi, h, pad);

      // stem
      buf.writeln(
        '<line x1="${x.toStringAsFixed(1)}" y1="$ay" '
        'x2="${x.toStringAsFixed(1)}" y2="${y.toStringAsFixed(1)}" '
        'stroke="$color" stroke-opacity="0.5" stroke-width="2" />',
      );

      // lollipop head
      final tip = htmlEscape.convert(
        '${series[i].commit} | ${series[i].fps.toStringAsFixed(2)} fps',
      );

      final circle =
          '''
<circle cx="${x.toStringAsFixed(1)}" cy="${y.toStringAsFixed(1)}" r="4" stroke="$color" stroke-width="2" fill="none"><title>$tip</title></circle>
''';

      buf.writeln(circle.replaceAll('\n', ''));
    }

    buf
      ..writeln('</svg>')
      ..writeln('</div>');
  });

  return buf.toString();
}

double _mapY(double v, double lo, double hi, int height, int pad) {
  final ay = height - pad;
  final ty = pad;
  final t = (v - lo) / ((hi - lo) == 0 ? 1 : (hi - lo));

  return ay - (ay - ty) * t;
}

double _max(double a, double b) => a > b ? a : b;
