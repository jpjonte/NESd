import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

/// One node per category, wrapping that category's row so navigation code
/// can focus the row's first tile. The nodes skip traversal: they are
/// handles, not stops. [debugLabel] names them as `<label> <category>`.
Map<SettingsCategory, FocusNode> useCategoryFocusNodes(String debugLabel) {
  final nodes = useMemoized(
    () => {
      for (final category in SettingsCategory.values)
        category: FocusNode(
          skipTraversal: true,
          debugLabel: '$debugLabel ${category.name}',
        ),
    },
  );

  useEffect(() {
    return () {
      for (final node in nodes.values) {
        node.dispose();
      }
    };
  }, [nodes]);

  return nodes;
}
