import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/release.dart';

class DownloadCards extends StatelessComponent {
  const DownloadCards({required this.release, super.key});

  final ReleaseManifest release;

  @override
  Component build(BuildContext context) {
    return div(classes: 'downloads', [
      _webCard(),
      for (final platform in DownloadPlatform.values) _card(platform),
    ]);
  }

  Component _webCard() => const div(classes: 'download-card', [
    h2([.text('Web')]),
    div(classes: 'download-links', [
      a(classes: 'dl primary', href: playUrl, [.text('Play in browser')]),
    ]),
  ]);

  Component _card(DownloadPlatform platform) {
    final assets = release.forPlatform(platform);

    final primary = assets.isEmpty
        ? a(classes: 'dl primary', href: release.releaseUrl.toString(), const [
            .text('Release page'),
          ])
        : a(classes: 'dl primary', href: assets.first.url.toString(), [
            .text(assets.first.label),
          ]);

    final more = [
      for (final asset in assets.skip(1))
        a(classes: 'dl', href: asset.url.toString(), [.text(asset.label)]),
      if (platform == DownloadPlatform.linux)
        const a(classes: 'dl', href: flatpakRepoUrl, [.text('Flatpak repo')]),
    ];

    return div(classes: 'download-card', [
      h2([.text(platform.label)]),
      div(classes: 'download-links', [primary]),
      if (more.isNotEmpty)
        details(classes: 'download-more', [
          const summary([.text('All formats')]),
          div(classes: 'download-links', more),
        ]),
    ]);
  }
}
