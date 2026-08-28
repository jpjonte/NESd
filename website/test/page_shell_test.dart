import 'package:jaspr/dom.dart';
import 'package:nesd_website/components/page_shell.dart';
import 'package:test/test.dart';

import 'render.dart';

void main() {
  test('wraps children in header, main and footer', () async {
    final html = await renderHtml(
      const PageShell(
        path: '/',
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

  String navOf(String html) =>
      html.substring(html.indexOf('<nav'), html.indexOf('</nav>'));

  test('nav carries the sections and GitHub, and nothing else', () async {
    final html = await renderHtml(const PageShell(path: '/', children: []));

    expect(html, contains('href="/#screenshots"'));
    expect(html, contains('href="/#features"'));
    expect(html, contains('href="https://github.com/jpjonte/NESd"'));

    final nav = navOf(html);

    expect('<a '.allMatches(nav), hasLength(3));
    expect(nav, isNot(contains('logo.svg')));
  });

  test('adds a home link away from the landing page', () async {
    final nav = navOf(
      await renderHtml(const PageShell(path: '/privacy', children: [])),
    );

    expect(nav, contains('<a class="site-brand" href="/">NESd</a>'));
    expect('<a '.allMatches(nav), hasLength(4));
  });

  test('leaves the landing page header without one', () async {
    final nav = navOf(
      await renderHtml(const PageShell(path: '/', children: [])),
    );

    expect(nav, isNot(contains('site-brand')));
  });

  test(
    'footer carries license, privacy, changelog, self-hosting and contact',
    () async {
      final html = await renderHtml(const PageShell(path: '/', children: []));

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
