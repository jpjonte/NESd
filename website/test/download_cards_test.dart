import 'package:nesd_website/components/download_cards.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/release.dart';
import 'package:test/test.dart';

import 'render.dart';

DownloadAsset _asset(DownloadPlatform platform, String label, String slug) =>
    DownloadAsset(
      platform: platform,
      label: label,
      url: Uri.parse('https://example.com/$slug'),
    );

ReleaseManifest _manifest(List<DownloadAsset> assets) => ReleaseManifest(
  version: '1.0.0',
  releaseUrl: Uri.parse('https://github.com/jpjonte/NESd/releases/tag/1.0.0'),
  assets: assets,
);

final _linuxAssets = [
  _asset(DownloadPlatform.linux, 'AppImage (x64)', 'appimage-x64'),
  _asset(DownloadPlatform.linux, 'AppImage (arm64)', 'appimage-arm64'),
  _asset(DownloadPlatform.linux, '.deb (x64)', 'deb-x64'),
  _asset(DownloadPlatform.linux, '.deb (arm64)', 'deb-arm64'),
  _asset(DownloadPlatform.linux, '.rpm (x64)', 'rpm-x64'),
  _asset(DownloadPlatform.linux, '.rpm (arm64)', 'rpm-arm64'),
];

final _singleAssets = [
  _asset(DownloadPlatform.macos, '.dmg', 'dmg'),
  _asset(DownloadPlatform.windows, '.zip', 'zip'),
  _asset(DownloadPlatform.android, '.apk', 'apk'),
];

Future<(String before, String inside)> _splitAtDisclosure(
  ReleaseManifest manifest,
) async {
  final html = await renderHtml(DownloadCards(release: manifest));
  final start = html.indexOf('<details');
  final end = html.indexOf('</details>');

  expect(start, greaterThanOrEqualTo(0), reason: 'no <details> in:\n$html');

  return (html.substring(0, start), html.substring(start, end));
}

void main() {
  test('shows the first linux asset as the primary button', () async {
    final (before, _) = await _splitAtDisclosure(
      _manifest([..._singleAssets, ..._linuxAssets]),
    );

    expect(
      before,
      contains(
        '<a class="dl primary" '
        'href="https://example.com/appimage-x64">AppImage (x64)</a>',
      ),
    );
  });

  test('tucks the remaining linux assets into the disclosure', () async {
    final (before, inside) = await _splitAtDisclosure(
      _manifest([..._singleAssets, ..._linuxAssets]),
    );

    for (final asset in _linuxAssets.skip(1)) {
      expect(before, isNot(contains(asset.label)));
      expect(inside, contains('>${asset.label}</a>'));
    }
  });

  test('labels the disclosure "All formats"', () async {
    final html = await renderHtml(
      DownloadCards(release: _manifest([..._singleAssets, ..._linuxAssets])),
    );

    expect(html, contains('<details class="download-more">'));
    expect(html, contains('<summary>All formats</summary>'));
  });

  test('moves the flatpak repo link into the disclosure', () async {
    final (before, inside) = await _splitAtDisclosure(
      _manifest([..._singleAssets, ..._linuxAssets]),
    );

    expect(before, isNot(contains(flatpakRepoUrl)));
    expect(inside, contains(flatpakRepoUrl));
  });

  test('gives single-asset platforms no disclosure', () async {
    final html = await renderHtml(
      DownloadCards(release: _manifest([..._singleAssets, ..._linuxAssets])),
    );

    expect('<details'.allMatches(html), hasLength(1));
  });

  test(
    'falls back to the release page inside a disclosure-only card',
    () async {
      final (before, inside) = await _splitAtDisclosure(
        _manifest(_singleAssets),
      );

      expect(
        before,
        contains(
          '<a class="dl primary" '
          'href="https://github.com/jpjonte/NESd/releases/tag/1.0.0">'
          'Release page</a>',
        ),
      );
      expect(inside, contains(flatpakRepoUrl));
    },
  );
}
