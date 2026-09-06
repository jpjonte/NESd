// Regenerates the test ROM table in README.md from the ROMs that the tests
// in test/test_roms/ run.

import 'dart:io';

import 'test_rom_table.dart';

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final root = _repoRoot();

  final sources = Directory('${root.path}/packages/nesd/test/test_roms')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .map((file) => file.readAsStringSync());

  final coverage = TestRomCoverage.fromSources(sources);
  final readme = File('${root.path}/README.md');
  final source = readme.readAsStringSync();

  final String updated;

  try {
    updated = updateTestRomTable(source, coverage);
  } on FormatException catch (exception) {
    _fail(exception.message);
  }

  final summary = '${coverage.passing.length} ROMs passing';

  if (source == updated) {
    stdout.writeln('test ROM table up to date ($summary)');

    return;
  }

  if (checkOnly) {
    _fail(
      'test ROM table is out of date. Run:\n'
      '  fvm dart run tool/update_test_roms.dart',
    );
  }

  readme.writeAsStringSync(updated);
  stdout.writeln('updated test ROM table ($summary)');
}

Directory _repoRoot() {
  final script = File.fromUri(Platform.script).parent;

  return script.parent.parent.parent;
}

Never _fail(String message) {
  stderr.writeln('update_test_roms: $message');
  exit(1);
}
