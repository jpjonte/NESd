import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/service_worker.dart';

BuildFile _file(String path, [String content = '']) =>
    BuildFile(path: path, bytes: utf8.encode(content));

String _sha256(String content) =>
    sha256.convert(utf8.encode(content)).toString();

const _source = '''
'use strict';

// generated:start
const cacheName = 'nesd-dev';
const shell = {};
const engine = {};
// generated:end

self.addEventListener('install', () => {});
''';

void main() {
  group('ServiceWorkerManifest.fromFiles', () {
    test('splits the build into shell and engine files', () {
      final manifest = ServiceWorkerManifest.fromFiles([
        _file('index.html', '<html>'),
        _file('flutter_bootstrap.js', 'boot'),
        _file('assets/assets/logo.png', 'png'),
        _file('main.dart.wasm', 'wasm'),
        _file('main.dart.mjs', 'mjs'),
        _file('main.dart.js', 'js'),
        _file('canvaskit/skwasm.js', 'skwasm'),
        _file('canvaskit/chromium/canvaskit.wasm', 'ck'),
      ], version: '0.20.0');

      expect(manifest.shell.keys, [
        'assets/assets/logo.png',
        'flutter_bootstrap.js',
        'index.html',
      ]);
      expect(manifest.engine.keys, [
        'canvaskit/chromium/canvaskit.wasm',
        'canvaskit/skwasm.js',
        'main.dart.js',
        'main.dart.mjs',
        'main.dart.wasm',
      ]);
    });

    test('hashes every file except index.html', () {
      final manifest = ServiceWorkerManifest.fromFiles([
        _file('index.html', '<html>'),
        _file('flutter_bootstrap.js', 'boot'),
        _file('main.dart.wasm', 'wasm'),
      ], version: '0.20.0');

      expect(manifest.shell['index.html'], isNull);
      expect(manifest.shell['flutter_bootstrap.js'], _sha256('boot'));
      expect(manifest.engine['main.dart.wasm'], _sha256('wasm'));
    });

    test('leaves out the workers, symbols, maps and dotfiles', () {
      final manifest = ServiceWorkerManifest.fromFiles([
        _file('index.html'),
        _file('sw.js'),
        _file('flutter_service_worker.js'),
        _file('canvaskit/skwasm.js.symbols'),
        _file('main.dart.js.map'),
        _file('.last_build_id'),
        _file('assets/.hidden/file'),
      ], version: '0.20.0');

      expect(manifest.shell.keys, ['index.html']);
      expect(manifest.engine, isEmpty);
    });

    test('names the cache after the version and the build contents', () {
      ServiceWorkerManifest build(String bootstrap) =>
          ServiceWorkerManifest.fromFiles([
            _file('index.html', '<html>'),
            _file('flutter_bootstrap.js', bootstrap),
          ], version: '0.20.0');

      final first = build('boot');

      expect(first.cacheName, matches(RegExp(r'^nesd-0\.20\.0-[0-9a-f]{8}$')));
      expect(build('boot').cacheName, first.cacheName);
      expect(build('changed').cacheName, isNot(first.cacheName));
    });

    test('does not let file order change the cache name', () {
      final a = _file('a.txt', 'a');
      final b = _file('b.txt', 'b');

      expect(
        ServiceWorkerManifest.fromFiles([a, b], version: '1').cacheName,
        ServiceWorkerManifest.fromFiles([b, a], version: '1').cacheName,
      );
    });
  });

  group('render', () {
    test('writes the generated block as JavaScript object literals', () {
      final manifest = ServiceWorkerManifest.fromFiles([
        _file('index.html', '<html>'),
        _file('flutter_bootstrap.js', 'boot'),
        _file('main.dart.wasm', 'wasm'),
      ], version: '0.20.0');

      expect(manifest.render(), '''
// generated:start
const cacheName = '${manifest.cacheName}';
const shell = {
  'flutter_bootstrap.js': '${_sha256('boot')}',
  'index.html': null,
};
const engine = {
  'main.dart.wasm': '${_sha256('wasm')}',
};
// generated:end''');
    });

    test('renders empty maps inline', () {
      final manifest = ServiceWorkerManifest.fromFiles(
        const [],
        version: '0.20.0',
      );

      expect(manifest.render(), contains('const shell = {};'));
      expect(manifest.render(), contains('const engine = {};'));
    });
  });

  group('fillServiceWorker', () {
    final manifest = ServiceWorkerManifest.fromFiles([
      _file('index.html', '<html>'),
      _file('main.dart.wasm', 'wasm'),
    ], version: '0.20.0');

    test('replaces the block and keeps the rest of the source', () {
      final filled = fillServiceWorker(_source, manifest);

      expect(filled, startsWith("'use strict';\n\n// generated:start\n"));
      expect(filled, contains("const cacheName = '${manifest.cacheName}';"));
      expect(filled, contains("'main.dart.wasm': '${_sha256('wasm')}',"));
      expect(filled, endsWith("self.addEventListener('install', () => {});\n"));
      expect(filled, isNot(contains('nesd-dev')));
    });

    test('is idempotent', () {
      final once = fillServiceWorker(_source, manifest);

      expect(fillServiceWorker(once, manifest), once);
    });

    test('refuses a source without the markers', () {
      expect(
        () => fillServiceWorker("'use strict';\n", manifest),
        throwsFormatException,
      );
    });

    test('fills in the real worker', () {
      final source = File('web/sw.js').readAsStringSync();
      final filled = fillServiceWorker(source, manifest);

      expect(source, contains("const cacheName = 'nesd-dev';"));
      expect(filled, isNot(contains('nesd-dev')));
      expect(filled, contains("const cacheName = '${manifest.cacheName}';"));
    });
  });
}
