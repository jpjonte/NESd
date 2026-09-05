// Regenerates the number of supported games in README.md and
// website/lib/content.dart from assets/nes20db.xml.

import 'dart:io';

import 'package:xml/xml.dart';

const includedCategories = {
  'Licensed Japan',
  'Licensed North America',
  'Licensed PAL',
  'Modern',
  'Multicarts',
  'Plug-and-Play',
  'Unlicensed China',
  'Unlicensed Elsewhere',
  'Unlicensed Japan',
  'Unlicensed North America',
  'Unlicensed South Korea',
  'Unlicensed Taiwan&Hong Kong',
};

const excludedCategories = {
  'BIOS',
  'Bad Dumps',
  'Bootleg Hacks',
  'Bootleg Singles',
  'Compatibility Hacks',
  'Educational Computers',
  'Homebrew',
  'Maintenance',
  'Playchoice',
  'Samples',
  'Unreleased',
  'Vs. System',
};

const startMarker = '<!-- game-counts:start -->';
const endMarker = '<!-- game-counts:end -->';

/// Mappers that aren't fully implemented yet. Ignored in README.md and
/// `supportedGameCount`.
const inProgressMapperIds = <int>{};

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final root = _repoRoot();

  final mappers = _supportedMappers(
    File('${root.path}/packages/nesd/lib/nes/cartridge/mapper/mapper.dart'),
  ).where((id) => !inProgressMapperIds.contains(id)).toList();

  final readme = File('${root.path}/README.md');
  final labels = _mapperLabels(readme);

  final missing = mappers.where((id) => !labels.containsKey(id)).toList();

  if (missing.isNotEmpty) {
    _fail(
      'no README label for mapper(s) ${missing.join(', ')}.\n'
      'Add a "- <id>: <name> (0 games)" line to the mapper list first',
    );
  }

  final counts = _countGames(
    File('${root.path}/packages/nesd/assets/nes20db.xml'),
    mappers,
  );

  final total = counts.values.fold(0, (sum, count) => sum + count);

  final block = _renderBlock(mappers, labels, counts, total);
  final content = File('${root.path}/website/lib/content.dart');

  final readmeChanged = _applyReadme(readme, block, checkOnly);
  final contentChanged = _applyContent(content, total, checkOnly);

  if (!readmeChanged && !contentChanged) {
    stdout.writeln('game counts up to date (${_formatCount(total)} games)');

    return;
  }

  if (checkOnly) {
    _fail(
      'game counts are out of date. Run:\n'
      '  fvm dart run tool/update_game_counts.dart',
    );
  }

  stdout.writeln('updated game counts (${_formatCount(total)} games)');
}

Directory _repoRoot() {
  final script = File.fromUri(Platform.script).parent;

  return script.parent.parent.parent;
}

List<int> _supportedMappers(File file) {
  final source = file.readAsStringSync();
  final switchBody = RegExp(
    r'factory Mapper\.fromId\([^)]*\)\s*\{.*?return switch \(mapperId\) \{(.*?)\};',
    dotAll: true,
  ).firstMatch(source);

  if (switchBody == null) {
    _fail('could not find the Mapper.fromId switch in ${file.path}');
  }

  final ids =
      RegExp(r'^\s*(\d+)\s*=>', multiLine: true)
          .allMatches(switchBody.group(1)!)
          .map((match) => int.parse(match.group(1)!))
          .toList()
        ..sort();

  if (ids.isEmpty) {
    _fail('found no mapper ids in ${file.path}');
  }

  return ids;
}

Map<int, String> _mapperLabels(File readme) {
  final pattern = RegExp(
    r'^- (\d+): (.+?) \([\d,.]+ games?\)$',
    multiLine: true,
  );

  return {
    for (final match in pattern.allMatches(readme.readAsStringSync()))
      int.parse(match.group(1)!): match.group(2)!,
  };
}

Map<int, int> _countGames(File database, List<int> mappers) {
  final document = XmlDocument.parse(database.readAsStringSync());
  final wanted = mappers.toSet();
  final counts = {for (final id in mappers) id: 0};
  final unknown = <String>{};

  for (final game in document.findAllElements('game')) {
    final category = _category(game);

    if (excludedCategories.contains(category)) {
      continue;
    }

    if (!includedCategories.contains(category)) {
      unknown.add(category);

      continue;
    }

    final mapper = int.tryParse(
      game.getElement('pcb')?.getAttribute('mapper') ?? '',
    );

    if (mapper != null && wanted.contains(mapper)) {
      counts[mapper] = counts[mapper]! + 1;
    }
  }

  if (unknown.isNotEmpty) {
    _fail(
      'unknown nes20db categories: ${(unknown.toList()..sort()).join(', ')}.\n'
      'Add each one to includedCategories or excludedCategories in '
      '${Platform.script.pathSegments.last}.',
    );
  }

  return counts;
}

String _category(XmlElement game) {
  final comment = game.children.whereType<XmlComment>().singleOrNull;

  if (comment == null) {
    _fail('a <game> element has no path comment');
  }

  return comment.value.trim().replaceAll('&amp;', '&').split(r'\').first.trim();
}

String _renderBlock(
  List<int> mappers,
  Map<int, String> labels,
  Map<int, int> counts,
  int total,
) {
  final lines = [
    startMarker,
    '',
    'NESd supports ${_formatCount(total)} games.',
    '',
    '<details>',
    '<summary>Supported mappers</summary>',
    '',
    for (final id in mappers)
      '- $id: ${labels[id]} (${_formatCount(counts[id]!)} games)',
    '',
    '</details>',
    '',
    endMarker,
  ];

  return lines.join('\n');
}

bool _applyReadme(File readme, String block, bool checkOnly) {
  final source = readme.readAsStringSync();
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);

  if (start < 0 || end < 0) {
    _fail('could not find $startMarker / $endMarker in ${readme.path}');
  }

  final updated = source.replaceRange(start, end + endMarker.length, block);

  return _write(readme, source, updated, checkOnly);
}

bool _applyContent(File content, int total, bool checkOnly) {
  final source = content.readAsStringSync();
  final pattern = RegExp("const supportedGameCount = '[^']*';");

  if (!pattern.hasMatch(source)) {
    _fail('could not find supportedGameCount in ${content.path}');
  }

  final updated = source.replaceFirst(
    pattern,
    "const supportedGameCount = '${_formatCount(total)}';",
  );

  return _write(content, source, updated, checkOnly);
}

bool _write(File file, String source, String updated, bool checkOnly) {
  if (source == updated) {
    return false;
  }

  if (!checkOnly) {
    file.writeAsStringSync(updated);
  }

  return true;
}

String _formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  return buffer.toString();
}

Never _fail(String message) {
  stderr.writeln('update_game_counts: $message');
  exit(1);
}
