import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/components/download_cards.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/release.dart';

class Hero extends StatelessComponent {
  const Hero({required this.release, super.key});

  final ReleaseManifest release;

  @override
  Component build(BuildContext context) {
    return section(classes: 'hero', [
      div(classes: 'container', [
        div(classes: 'hero-copy', [
          const h1([.text('A cycle-accurate NES emulator')]),
          const div(classes: 'accent-rule', []),
          const p(classes: 'tagline', [
            .text(
              'Free and open source. Plays $supportedGameCount games on '
              'macOS, Windows, Linux and Android.',
            ),
          ]),
          DownloadCards(release: release),
          p(classes: 'release-meta', [
            .text('Version ${release.version} · '),
            const a(href: releasesUrl, [.text('All releases')]),
            const .text(' · '),
            const a(href: nightlyUrl, [.text('Nightly')]),
          ]),
        ]),
        const div(classes: 'hero-logo', [
          img(src: 'img/logo.svg', alt: 'NESd logo', width: 280, height: 280),
        ]),
      ]),
    ]);
  }
}
