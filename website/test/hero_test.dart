import 'package:nesd_website/components/hero.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/release.dart';
import 'package:test/test.dart';

import 'render.dart';

ReleaseManifest _manifest({DateTime? publishedAt}) => ReleaseManifest(
  version: '1.2.3',
  releaseUrl: Uri.parse('https://github.com/jpjonte/NESd/releases/tag/1.2.3'),
  assets: [
    DownloadAsset(
      platform: DownloadPlatform.macos,
      label: '.dmg',
      url: Uri.parse('https://example.com/dmg'),
    ),
  ],
  publishedAt: publishedAt,
);

void main() {
  test('leads with what a visitor can do, not the technique', () async {
    final html = await renderHtml(Hero(release: _manifest()));

    expect(html, contains('<h1>Play NES games anywhere</h1>'));
  });

  test('links the game count to the mapper list', () async {
    final html = await renderHtml(Hero(release: _manifest()));

    expect(html, contains('href="$mappersUrl">$supportedGameCount games</a>'));
  });

  test('shows the release date when the manifest carries one', () async {
    final html = await renderHtml(
      Hero(release: _manifest(publishedAt: DateTime.utc(2026, 8, 21))),
    );

    expect(html, contains('Version 1.2.3 · 21 August 2026'));
  });

  test('omits the date when the manifest has none', () async {
    final html = await renderHtml(Hero(release: _manifest()));

    expect(html, contains('Version 1.2.3 · <a'));
  });

  test('offers the changelog next to the version', () async {
    final html = await renderHtml(Hero(release: _manifest()));

    expect(html, contains('href="$changelogUrl">What\'s new</a>'));
  });
}
