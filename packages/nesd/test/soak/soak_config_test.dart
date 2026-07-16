import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/soak/soak_config.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory base;

  setUp(() {
    base = Directory.systemTemp.createTempSync('nesd_soak');
  });

  tearDown(() {
    base.deleteSync(recursive: true);
  });

  File marker() => File(p.join(base.path, 'soak', 'soak.json'));

  test('returns null when no marker exists', () async {
    expect(await maybeReadSoakConfig(baseDirectory: base), isNull);
  });

  test('reads config, applies defaults, deletes the marker', () async {
    marker()
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'rom': 'smb3.nes'}));

    final config = await maybeReadSoakConfig(baseDirectory: base);

    expect(config, isNotNull);
    expect(config!.romPath, p.join(base.path, 'soak', 'smb3.nes'));
    expect(config.seconds, 600);
    expect(config.pcm, isTrue);
    expect(config.statsPath, p.join(base.path, 'soak', 'stats.log'));
    expect(config.pcmPath, p.join(base.path, 'soak', 'audio.pcm'));
    expect(marker().existsSync(), isFalse);
  });

  test('honors explicit seconds and pcm', () async {
    marker()
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({'rom': 'a.nes', 'seconds': 30, 'pcm': false}),
      );

    final config = await maybeReadSoakConfig(baseDirectory: base);

    expect(config!.seconds, 30);
    expect(config.pcm, isFalse);
  });

  test('returns null on malformed JSON and still deletes the marker', () async {
    marker()
      ..createSync(recursive: true)
      ..writeAsStringSync('{nope');

    expect(await maybeReadSoakConfig(baseDirectory: base), isNull);
    expect(marker().existsSync(), isFalse);
  });
}
