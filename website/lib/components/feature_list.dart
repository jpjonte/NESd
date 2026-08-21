import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/content.dart';

class FeatureList extends StatelessComponent {
  const FeatureList({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'features', classes: 'features', [
      div(classes: 'container', [
        const h2([.text('Features')]),
        ul(classes: 'feature-list', [
          for (final feature in features) li([.text(feature)]),
        ]),
      ]),
    ]);
  }
}
