import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nesd_website/components/page_shell.dart';

class PrivacyPage extends StatelessComponent {
  const PrivacyPage({required this.markdown, super.key});

  final String markdown;

  @override
  Component build(BuildContext context) {
    final html = md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    return PageShell(
      children: [
        article(classes: 'prose container', [RawText(html)]),
      ],
    );
  }
}
