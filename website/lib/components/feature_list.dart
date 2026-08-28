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
        div(classes: 'feature-groups', [
          for (final group in featureGroups)
            div(classes: 'feature-group', [
              h3([.text(group.title)]),
              ul(classes: 'feature-list', [
                for (final feature in group.features) li([.text(feature)]),
              ]),
            ]),
        ]),
      ]),
    ]);
  }
}
