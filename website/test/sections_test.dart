import 'package:nesd_website/components/feature_list.dart';
import 'package:nesd_website/components/screenshot_strip.dart';
import 'package:nesd_website/content.dart';
import 'package:test/test.dart';

import 'render.dart';

void main() {
  group('screenshots', () {
    test('gives the section a visible heading', () async {
      final html = await renderHtml(const ScreenshotStrip());

      expect(html, contains('<h2>Screenshots</h2>'));
      expect(html, isNot(contains('visually-hidden')));
    });

    test('captions every shot', () async {
      final html = await renderHtml(const ScreenshotStrip());

      for (final shot in screenshots) {
        expect(html, contains('alt="${shot.alt}"'));
        expect(html, contains('>${shot.caption}</span>'));
      }
    });

    test('opens an overlay rather than the raw image file', () async {
      final html = await renderHtml(const ScreenshotStrip());

      for (final shot in screenshots) {
        final id = shot.file.split('.').first;

        expect(html, contains('href="#shot-$id"'));
        expect(html, contains('id="shot-$id" class="lightbox"'));
      }

      expect(html, isNot(contains('href="img/')));
    });

    test('offers a way out of the overlay', () async {
      final html = await renderHtml(const ScreenshotStrip());

      expect(
        'href="#screenshots"'.allMatches(html),
        hasLength(screenshots.length * 2),
      );
    });

    test('keeps the images lazy', () async {
      final html = await renderHtml(const ScreenshotStrip());

      expect(
        'loading="lazy"'.allMatches(html),
        hasLength(screenshots.length * 2),
      );
    });
  });

  group('features', () {
    test('groups features under their own headings', () async {
      final html = await renderHtml(const FeatureList());

      for (final group in featureGroups) {
        expect(html, contains('<h3>${group.title}</h3>'));

        for (final feature in group.features) {
          expect(html, contains('<li>$feature</li>'));
        }
      }
    });

    test('separates player features from internals', () {
      final playing = featureGroups.first;

      expect(playing.title, 'Playing');
      expect(playing.features, contains('Save states'));
      expect(playing.features, isNot(contains('Debugger and execution log')));
    });
  });
}
