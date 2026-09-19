import 'dart:convert';

import 'package:crypto/crypto.dart';

const startMarker = '// generated:start';
const endMarker = '// generated:end';

const unverifiedFiles = {'index.html'};

class BuildFile {
  const BuildFile({required this.path, required this.bytes});

  final String path;
  final List<int> bytes;
}

bool isCachedFile(String path) {
  final segments = path.split('/');

  if (segments.any((segment) => segment.startsWith('.'))) {
    return false;
  }

  if (path == 'sw.js' || path == 'flutter_service_worker.js') {
    return false;
  }

  return !path.endsWith('.symbols') && !path.endsWith('.map');
}

bool isEngineFile(String path) =>
    path.startsWith('main.dart.') || path.startsWith('canvaskit/');

class ServiceWorkerManifest {
  const ServiceWorkerManifest({
    required this.cacheName,
    required this.shell,
    required this.engine,
  });

  factory ServiceWorkerManifest.fromFiles(
    Iterable<BuildFile> files, {
    required String version,
  }) {
    final shell = <String, String?>{};
    final engine = <String, String>{};

    for (final file in files) {
      if (!isCachedFile(file.path)) {
        continue;
      }

      final hash = sha256.convert(file.bytes).toString();

      if (isEngineFile(file.path)) {
        engine[file.path] = hash;
      } else {
        shell[file.path] = unverifiedFiles.contains(file.path) ? null : hash;
      }
    }

    final entries = [
      for (final MapEntry(:key, :value) in {...shell, ...engine}.entries)
        '$key $value',
    ]..sort();

    final buildHash = sha256.convert(utf8.encode(entries.join('\n')));
    final cacheName = 'nesd-$version-${buildHash.toString().substring(0, 8)}';

    return ServiceWorkerManifest(
      cacheName: cacheName,
      shell: _sorted(shell),
      engine: _sorted(engine),
    );
  }

  final String cacheName;
  final Map<String, String?> shell;
  final Map<String, String> engine;

  String render() {
    final buffer = StringBuffer()
      ..writeln(startMarker)
      ..writeln("const cacheName = '$cacheName';")
      ..writeln('const shell = ${_object(shell)};')
      ..writeln('const engine = ${_object(engine)};')
      ..write(endMarker);

    return buffer.toString();
  }

  static Map<String, V> _sorted<V>(Map<String, V> map) => {
    for (final key in map.keys.toList()..sort()) key: map[key] as V,
  };

  static String _object(Map<String, String?> map) {
    if (map.isEmpty) {
      return '{}';
    }

    final buffer = StringBuffer('{\n');

    for (final MapEntry(:key, :value) in map.entries) {
      final hash = value == null ? 'null' : "'$value'";

      buffer.writeln("  '$key': $hash,");
    }

    return (buffer..write('}')).toString();
  }
}

String fillServiceWorker(String source, ServiceWorkerManifest manifest) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);

  if (start < 0 || end < start) {
    throw const FormatException(
      'sw.js lacks the "$startMarker" / "$endMarker" markers',
    );
  }

  return source.replaceRange(start, end + endMarker.length, manifest.render());
}
