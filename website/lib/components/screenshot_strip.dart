import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';

class ScreenshotStrip extends StatelessComponent {
  const ScreenshotStrip({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'screenshots', classes: 'screenshots', [
      div(classes: 'container', [
        const h2(classes: 'visually-hidden', [.text('Screenshots')]),
        for (final shot in screenshots)
          img(
            src: 'img/${shot.file}',
            alt: shot.alt,
            loading: MediaLoading.lazy,
          ),
      ]),
    ]);
  }
}
