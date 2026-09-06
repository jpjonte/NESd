class TestRomCoverage {
  const TestRomCoverage({required this.passing, required this.failing});

  factory TestRomCoverage.fromSources(Iterable<String> sources) {
    final passing = <String>{};
    final failing = <String>{};

    for (final source in sources) {
      final knownFailures = _knownFailuresBlock.firstMatch(source)?.group(1);

      if (knownFailures != null) {
        failing.addAll(_romPaths(knownFailures));
      }

      passing.addAll(_romPaths(source));
    }

    passing.removeAll(failing);

    return TestRomCoverage(passing: passing, failing: failing);
  }

  final Set<String> passing;

  final Set<String> failing;

  Set<String> get suites => {
    for (final rom in passing.followedBy(failing)) _suiteOf(rom),
  };

  int passingIn(String suite) =>
      passing.where((rom) => _suiteOf(rom) == suite).length;
}

const startMarker = '<!-- test-roms:start -->';
const endMarker = '<!-- test-roms:end -->';

String updateTestRomTable(String readme, TestRomCoverage coverage) {
  final start = readme.indexOf(startMarker);
  final end = readme.indexOf(endMarker);

  if (start < 0 || end < 0) {
    throw const FormatException(
      'could not find $startMarker / $endMarker in README.md',
    );
  }

  final block = readme.substring(start, end);

  if (!_summary.hasMatch(block)) {
    throw const FormatException(
      'could not find the "N of M test ROMs run in CI and pass" sentence '
      'between the test-roms markers',
    );
  }

  final seen = <String>{};
  var tableTotal = 0;

  final rows = block.replaceAllMapped(_row, (match) {
    final suite = match.group(2)!;
    final total = int.parse(match.group(4)!);
    final passing = coverage.passingIn(suite);

    if (!coverage.suites.contains(suite)) {
      throw FormatException(
        'no test runs a ROM from `$suite`; remove its README row',
      );
    }

    if (passing > total) {
      throw FormatException(
        '$passing `$suite` ROMs pass but its README row says $total; '
        'raise the total',
      );
    }

    seen.add(suite);
    tableTotal += total;

    return '${match.group(1)}$suite${match.group(3)}$passing / $total'
        '${match.group(5)}';
  });

  final missing = coverage.suites.where((suite) => !seen.contains(suite));

  if (missing.isNotEmpty) {
    throw FormatException(
      'no README row for suite(s) ${(missing.toList()..sort()).join(', ')}.\n'
      'Add a "| <area> | `<suite>` | <author> | 0 / <total> | <notes> |" '
      'row to the test ROM table first',
    );
  }

  final updated = rows.replaceFirst(
    _summary,
    _renderSummary(coverage.passing.length, tableTotal),
  );

  return readme.replaceRange(start, end, updated);
}

/// The denominator is the sum of the suite sizes in the table, so the
/// sentence never claims more than the rows below it show.
String _renderSummary(int passing, int total) {
  final count = passing == total ? 'All $total' : '$passing of $total';

  return '$count test ROMs run in CI and pass.';
}

final _knownFailuresBlock = RegExp(
  r'_knownFailures\s*=\s*<String,\s*int>\{(.*?)\};',
  dotAll: true,
);

/// A single-quoted `.nes` literal, minus the `$_base/` or `../../roms/test/`
/// prefix the tests spell it with.
final _romLiteral = RegExp(r"'(?:\$_base/|\.\./\.\./roms/test/)?([^']+\.nes)'");

/// `| Area | `suite` | Author | passing / total | Notes |`
final _row = RegExp(
  r'^(\| [^|]* \| `)([^`]+)(` \| [^|]* \| )\d+ / (\d+)( \|[^|]*\|)$',
  multiLine: true,
);

final _summary = RegExp(
  r'(?:All \d+|\d+ of \d+) test ROMs run in CI and pass\.',
);

Iterable<String> _romPaths(String source) =>
    _romLiteral.allMatches(source).map((match) => match.group(1)!);

String _suiteOf(String rom) => rom.split('/').first;
