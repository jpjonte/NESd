import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nesd_website/components/page_shell.dart';

class const PrivacyPage({required final String markdown, super.key})
    extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final html = md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    return PageShell(
      path: '/privacy',
      children: [
        article(classes: 'prose container', [RawText(html)]),
      ],
    );
  }
}
