import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/pages/landing_page.dart';
import 'package:nesd_website/pages/privacy_page.dart';

class App extends StatelessComponent {
  const App({required this.content, super.key});

  final SiteContent content;

  @override
  Component build(BuildContext context) {
    return Document(
      lang: 'en',
      title: siteTitle,
      meta: const {'description': siteDescription, 'theme-color': '#111111'},
      head: [
        const link(rel: 'stylesheet', href: 'styles.css'),
        const link(rel: 'icon', type: 'image/svg+xml', href: 'img/logo.svg'),
        const link(rel: 'icon', type: 'image/png', href: 'img/favicon.png'),
        const meta(attributes: {'property': 'og:type', 'content': 'website'}),
        const meta(attributes: {'property': 'og:title', 'content': siteTitle}),
        const meta(
          attributes: {
            'property': 'og:description',
            'content': siteDescription,
          },
        ),
        const meta(
          attributes: {
            'property': 'og:image',
            'content': '$siteUrl/img/og.png',
          },
        ),
        const meta(attributes: {'property': 'og:url', 'content': siteUrl}),
        const meta(name: 'twitter:card', content: 'summary_large_image'),
      ],
      body: Router(
        routes: [
          Route(
            path: '/',
            title: siteTitle,
            builder: (context, state) => LandingPage(release: content.release),
          ),
          Route(
            path: '/privacy',
            title: 'Privacy Policy - NESd',
            builder: (context, state) =>
                PrivacyPage(markdown: content.privacyMarkdown),
          ),
        ],
      ),
    );
  }
}
