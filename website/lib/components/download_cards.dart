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
      for (final platform in DownloadPlatform.values) _card(platform),
    ]);
  }

  Component _card(DownloadPlatform platform) {
    final assets = release.forPlatform(platform);

    return div(classes: 'download-card', [
      h2([.text(platform.label)]),
      div(classes: 'download-links', [
        if (assets.isEmpty)
          a(classes: 'dl primary', href: release.releaseUrl.toString(), const [
            .text('Release page'),
          ]),
        for (final (index, asset) in assets.indexed)
          a(
            classes: index == 0 ? 'dl primary' : 'dl',
            href: asset.url.toString(),
            [.text(asset.label)],
          ),
        if (platform == DownloadPlatform.linux)
          const a(classes: 'dl', href: flatpakRepoUrl, [.text('Flatpak repo')]),
      ]),
    ]);
  }
}
