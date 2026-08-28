import 'dart:convert';

import 'package:nesd_website/app.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/release.dart';
import 'package:test/test.dart';

import 'render.dart';

final _content = SiteContent(
  release: ReleaseManifest(
    version: '1.2.3',
    releaseUrl: Uri.parse('https://github.com/jpjonte/NESd/releases/tag/1.2.3'),
    assets: [
      DownloadAsset(
        platform: DownloadPlatform.macos,
        label: '.dmg',
        url: Uri.parse('https://example.com/dmg'),
      ),
    ],
  ),
  privacyMarkdown: '# NESd Privacy Policy\n',
);

Future<String> _renderPage(String path) =>
    renderHtml(App(content: _content), path: path, fullDocument: true);

Map<String, Object?> _structuredData(String html) {
  const open = '<script type="application/ld+json">';
  final start = html.indexOf(open);

  expect(start, greaterThanOrEqualTo(0), reason: 'no ld+json in:\n$html');

  final end = html.indexOf('</script>', start);
  final json = html.substring(start + open.length, end);

  return jsonDecode(json) as Map<String, Object?>;
}

void main() {
  test('uses the N-only favicon, not the full logo', () async {
    final html = await _renderPage('/');

    expect(html, contains('href="img/favicon.svg"'));
    expect(html, contains('rel="apple-touch-icon"'));
    expect(
      html,
      isNot(
        contains(
          'rel="icon" type="image/svg+xml" '
          'href="img/logo.svg"',
        ),
      ),
    );
  });

  test('each page declares its own canonical url', () async {
    expect(await _renderPage('/'), contains('href="$siteUrl/"'));
    expect(await _renderPage('/privacy'), contains('href="$siteUrl/privacy"'));
  });

  test('describes NESd as free software for search engines', () async {
    final data = _structuredData(await _renderPage('/'));

    expect(data['@type'], 'SoftwareApplication');
    expect(data['name'], 'NESd');
    expect(data['softwareVersion'], '1.2.3');
    expect(data['isAccessibleForFree'], isTrue);
    expect((data['offers']! as Map)['price'], '0');
  });

  test('carries alt text for the social preview image', () async {
    final html = await _renderPage('/');

    expect(html, contains('og:image:alt'));
  });
}
