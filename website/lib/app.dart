import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/pages/landing_page.dart';
import 'package:nesd_website/pages/privacy_page.dart';
import 'package:nesd_website/release.dart';

String _structuredData(ReleaseManifest release) => jsonEncode({
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  'name': 'NESd',
  'description': siteDescription,
  'url': siteUrl,
  'applicationCategory': 'GameApplication',
  'operatingSystem': 'macOS, Windows, Linux, Android, Web',
  'softwareVersion': release.version,
  'license': 'https://opensource.org/licenses/MIT',
  'isAccessibleForFree': true,
  'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'EUR'},
  'author': {'@type': 'Person', 'name': 'Buddy Jonte'},
});

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
        const link(rel: 'icon', type: 'image/svg+xml', href: 'img/favicon.svg'),
        const link(rel: 'icon', type: 'image/png', href: 'img/favicon.png'),
        const link(rel: 'apple-touch-icon', href: 'img/apple-touch-icon.png'),
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
        const meta(
          attributes: {'property': 'og:image:alt', 'content': 'The NESd logo'},
        ),
        const meta(attributes: {'property': 'og:url', 'content': siteUrl}),
        const meta(name: 'twitter:card', content: 'summary_large_image'),
        Component.element(
          tag: 'script',
          attributes: const {'type': 'application/ld+json'},
          children: [RawText(_structuredData(content.release))],
        ),
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
