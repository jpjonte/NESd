import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:nesd_website/content.dart';

class PageShell extends StatelessComponent {
  const PageShell({required this.children, required this.path, super.key});

  final List<Component> children;

  final String path;

  @override
  Component build(BuildContext context) {
    return div(classes: 'page', [
      Document.head(
        children: [link(rel: 'canonical', href: '$siteUrl$path')],
      ),
      header(classes: 'site-header', [
        nav(classes: 'container', [
          if (path != '/')
            const a(classes: 'site-brand', href: '/', [.text('NESd')]),
          const ul(classes: 'nav-links', [
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
