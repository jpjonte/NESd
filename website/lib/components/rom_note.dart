import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';

class RomNote extends StatelessComponent {
  const RomNote({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'games', classes: 'rom-note', [
      div(classes: 'container', [
        const div(classes: 'rom-note-copy', [
          h2([.text('You bring the games')]),
          p([
            .text(
              'NESd ships without games, so you supply the ROMs: dumps of '
              'cartridges you own, or homebrew. Open a ',
            ),
            code([.text('.nes')]),
            .text(' file, or a '),
            code([.text('.zip')]),
            .text(' with one inside, and NESd does the rest.'),
          ]),
          p([
            .text(
              'People are still making new NES games. These are good places '
              'to start:',
            ),
          ]),
        ]),
        ul(classes: 'rom-sources', [
          for (final source in romSources)
            li([
              a(href: source.url, [.text(source.label)]),
              span(classes: 'rom-source-note', [.text(source.note)]),
            ]),
        ]),
      ]),
    ]);
  }
}
