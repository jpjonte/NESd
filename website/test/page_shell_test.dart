import 'package:jaspr/dom.dart';
import 'package:nesd_website/components/page_shell.dart';
import 'package:test/test.dart';

import 'render.dart';

void main() {
  test('wraps children in header, main and footer', () async {
    final html = await renderHtml(
      const PageShell(
        children: [
          p([.text('body-marker')]),
        ],
      ),
    );

    expect(html, contains('<header class="site-header">'));
    expect(html, contains('<main>'));
    expect(html, contains('body-marker'));
    expect(html, contains('<footer class="site-footer">'));
  });

  test('nav links to the brand, sections and GitHub', () async {
    final html = await renderHtml(const PageShell(children: []));

    expect(html, contains('<a class="brand" href="/">'));
    expect(html, contains('href="/#screenshots"'));
    expect(html, contains('href="/#features"'));
    expect(html, contains('href="https://github.com/jpjonte/NESd"'));
  });

  test(
    'footer carries license, privacy, changelog, self-hosting and contact',
    () async {
      final html = await renderHtml(const PageShell(children: []));

      expect(html, contains('© Buddy Jonte · MIT License'));
      expect(html, contains('href="/privacy"'));
      expect(
        html,
        contains(
          'href="https://github.com/jpjonte/NESd/blob/main/CHANGELOG.md"',
        ),
      );
      expect(html, contains('>Self-hosting<'));
      expect(html, contains('href="mailto:nesd@jpj.dev"'));
    },
  );
}
