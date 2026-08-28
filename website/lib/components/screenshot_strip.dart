import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';

class ScreenshotStrip extends StatelessComponent {
  const ScreenshotStrip({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'screenshots', classes: 'screenshots', [
      div(classes: 'container', [
        const h2([.text('Screenshots')]),
        ul(classes: 'screenshot-grid', [
          for (final shot in screenshots) _shot(shot),
        ]),
      ]),
    ]);
  }

  Component _shot(Screenshot shot) {
    final id = shot.file.split('.').first;

    return li(classes: shot.wide ? 'shot wide' : 'shot', [
      a(classes: 'shot-open', href: '#shot-$id', [
        img(src: 'img/${shot.file}', alt: shot.alt, loading: MediaLoading.lazy),
      ]),
      span(classes: 'screenshot-caption', [.text(shot.caption)]),
      div(id: 'shot-$id', classes: 'lightbox', [
        const a(
          classes: 'lightbox-dismiss',
          href: '#screenshots',
          attributes: {'aria-label': 'Close'},
          [],
        ),
        img(src: 'img/${shot.file}', alt: shot.alt, loading: MediaLoading.lazy),
        const a(classes: 'lightbox-close', href: '#screenshots', [.text('×')]),
      ]),
    ]);
  }
}
