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
        const div(classes: 'hero-top', [
          div(classes: 'hero-copy', [
            h1([.text('Play NES games anywhere')]),
            div(classes: 'accent-rule', []),
            p(classes: 'tagline', [
              .text(
                'A free, open-source, cycle-accurate emulator for macOS, '
                'Windows, Linux, Android and your browser. Plays ',
              ),
              a(classes: 'tagline-link', href: mappersUrl, [
                .text('$supportedGameCount games'),
              ]),
              .text('.'),
            ]),
          ]),
          div(classes: 'hero-logo', [
            img(src: 'img/logo.svg', alt: 'NESd logo', width: 220, height: 220),
          ]),
        ]),
        DownloadCards(release: release),
        p(classes: 'release-meta', [
          .text('Version ${release.version}'),
          if (release.releaseDate case final date?) .text(' · $date'),
          const .text(' · '),
          const a(href: changelogUrl, [.text("What's new")]),
          const .text(' · '),
          const a(href: releasesUrl, [.text('All releases')]),
          const .text(' · '),
          const a(href: nightlyUrl, [.text('Nightly')]),
        ]),
      ]),
    ]);
  }
}
