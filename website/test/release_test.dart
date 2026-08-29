import 'dart:convert';
import 'dart:io';

import 'package:nesd_website/release.dart';
import 'package:test/test.dart';

Map<String, Object?> _fixture() {
  final text = File('test/fixtures/release_0.16.0.json').readAsStringSync();

  return jsonDecode(text) as Map<String, Object?>;
}

Map<String, Object?> _manifestWith(List<String> assetNames) => {
  'tag_name': '1.0.0',
  'html_url': 'https://github.com/jpjonte/NESd/releases/tag/1.0.0',
  'assets': [
    for (final name in assetNames)
      {
        'name': name,
        'browser_download_url':
            'https://github.com/jpjonte/NESd/releases/download/1.0.0/$name',
      },
  ],
};

void main() {
  group('ReleaseManifest.fromJson', () {
    test('reads version and release url', () {
      final manifest = ReleaseManifest.fromJson(_fixture());

      expect(manifest.version, '0.16.0');
      expect(
        manifest.releaseUrl,
        Uri.parse('https://github.com/jpjonte/NESd/releases/tag/0.16.0'),
      );
    });

    test('groups the 0.16.0 assets by platform with labels in order', () {
      final manifest = ReleaseManifest.fromJson(_fixture());

      List<String> labels(DownloadPlatform platform) => [
        for (final asset in manifest.forPlatform(platform)) asset.label,
      ];

      expect(labels(DownloadPlatform.macos), ['.dmg']);
      expect(labels(DownloadPlatform.windows), ['.zip']);
      expect(labels(DownloadPlatform.linux), [
        'AppImage (x64)',
        'AppImage (arm64)',
        '.rpm (x64)',
        '.rpm (arm64)',
      ]);
      expect(labels(DownloadPlatform.android), ['.apk']);
    });

    test('keeps the browser download url of each asset', () {
      final manifest = ReleaseManifest.fromJson(_fixture());

      final dmg = manifest.forPlatform(DownloadPlatform.macos).single;

      expect(
        dmg.url,
        Uri.parse(
          'https://github.com/jpjonte/NESd/releases/download/0.16.0/'
          'nesd.0.16.0.macos-universal.dmg',
        ),
      );
    });

    test('ignores assets that match no suffix', () {
      final manifest = ReleaseManifest.fromJson(_fixture());

      final names = [for (final asset in manifest.assets) asset.url.path];

      expect(names, isNot(contains(endsWith('artifact.tar'))));
      expect(names, isNot(contains(endsWith('/nesd.deb'))));
      expect(names, isNot(contains(endsWith('dev.jpj.NESd.flatpak'))));
    });

    test('orders linux assets AppImage, deb, rpm, flatpak; x64 first', () {
      final manifest = ReleaseManifest.fromJson(
        _manifestWith([
          'nesd.1.0.0.linux-arm64.flatpak',
          'nesd.1.0.0.linux-x64.flatpak',
          'nesd.1.0.0.linux-arm64.deb',
          'nesd.1.0.0.linux-x64.AppImage',
          'nesd.1.0.0.linux-x64.deb',
          'nesd.1.0.0.linux-x64.rpm',
        ]),
      );

      expect(
        [for (final a in manifest.forPlatform(DownloadPlatform.linux)) a.label],
        [
          'AppImage (x64)',
          '.deb (x64)',
          '.deb (arm64)',
          '.rpm (x64)',
          '.flatpak (x64)',
          '.flatpak (arm64)',
        ],
      );
    });

    test('returns an empty list for a platform without assets', () {
      final manifest = ReleaseManifest.fromJson(
        _manifestWith(['nesd.1.0.0.macos-universal.dmg']),
      );

      expect(manifest.forPlatform(DownloadPlatform.android), isEmpty);
    });

    test('throws when no asset matches at all', () {
      expect(
        () => ReleaseManifest.fromJson(_manifestWith(['artifact.tar'])),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('no release asset matched'),
          ),
        ),
      );
    });

    test('throws when tag_name is missing', () {
      final json = _manifestWith(['nesd.1.0.0.macos-universal.dmg'])
        ..remove('tag_name');

      expect(
        () => ReleaseManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('formats published_at as a readable release date', () {
      final json = _manifestWith(['nesd.1.0.0.macos-universal.dmg'])
        ..['published_at'] = '2026-08-21T19:07:49Z';

      expect(ReleaseManifest.fromJson(json).releaseDate, '21 August 2026');
    });

    test('has no release date when published_at is absent', () {
      final json = _manifestWith(['nesd.1.0.0.macos-universal.dmg'])
        ..remove('published_at');

      expect(ReleaseManifest.fromJson(json).releaseDate, isNull);
    });

    test('survives an unparsable published_at', () {
      final json = _manifestWith(['nesd.1.0.0.macos-universal.dmg'])
        ..['published_at'] = 'not a date';

      expect(ReleaseManifest.fromJson(json).releaseDate, isNull);
    });
  });
}
