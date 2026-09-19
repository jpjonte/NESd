import 'dart:io';

import 'service_worker.dart';

void main(List<String> args) {
  if (args.length > 1) {
    _fail('usage: generate_service_worker.dart [build-dir]');
  }

  final root = _packageRoot();
  final buildDir = Directory(
    args.isEmpty ? '${root.path}/build/web' : args.single,
  );

  if (!buildDir.existsSync()) {
    _fail('${buildDir.path} does not exist. Run `flutter build web` first');
  }

  final worker = File('${buildDir.path}/sw.js');

  if (!worker.existsSync()) {
    _fail('${worker.path} missing. Is web/sw.js part of the build?');
  }

  final version = _version(File('${root.path}/pubspec.yaml'));
  final files = buildDir
      .listSync(recursive: true)
      .whereType<File>()
      .map(
        (file) => BuildFile(
          path: _relative(file, buildDir),
          bytes: file.readAsBytesSync(),
        ),
      );

  final manifest = ServiceWorkerManifest.fromFiles(files, version: version);

  final String filled;

  try {
    filled = fillServiceWorker(worker.readAsStringSync(), manifest);
  } on FormatException catch (exception) {
    _fail(exception.message);
  }

  worker.writeAsStringSync(filled);

  stdout.writeln(
    'service worker: ${manifest.cacheName}, '
    '${manifest.shell.length} shell files, '
    '${manifest.engine.length} engine files',
  );
}

String _relative(File file, Directory root) {
  final prefix = '${root.path}${Platform.pathSeparator}';

  return file.path.substring(prefix.length).replaceAll('\\', '/');
}

String _version(File pubspec) {
  final match = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());

  if (match == null) {
    _fail('no version in ${pubspec.path}');
  }

  return match[1]!.split('+').first;
}

Directory _packageRoot() => File.fromUri(Platform.script).parent.parent;

Never _fail(String message) {
  stderr.writeln('generate_service_worker: $message');
  exit(1);
}
