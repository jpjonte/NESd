import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';

class PageShell extends StatelessComponent {
  const PageShell({required this.children, super.key});

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(classes: 'page', [
      const header(classes: 'site-header', [
        nav(classes: 'container', [
          a(classes: 'brand', href: '/', [
            img(src: 'img/logo.svg', alt: '', width: 32, height: 32),
            span([.text('NESd')]),
          ]),
          ul(classes: 'nav-links', [
            li([
              a(href: '/#screenshots', [.text('Screenshots')]),
            ]),
            li([
              a(href: '/#features', [.text('Features')]),
            ]),
            li([
              a(href: repoUrl, [.text('GitHub')]),
            ]),
          ]),
        ]),
      ]),
      main_(children),
      const footer(classes: 'site-footer', [
        div(classes: 'container', [
          p([.text('© Buddy Jonte · MIT License')]),
          ul([
            li([
              a(href: '/privacy', [.text('Privacy')]),
            ]),
            li([
              a(href: changelogUrl, [.text('Changelog')]),
            ]),
            li([
              a(href: selfHostingUrl, [.text('Self-hosting')]),
            ]),
            li([
              a(href: repoUrl, [.text('GitHub')]),
            ]),
            li([
              a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }
}
