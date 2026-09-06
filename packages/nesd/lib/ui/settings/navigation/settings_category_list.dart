import 'dart:async';

import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/navigation/category_focus_nodes.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class SettingsCategoryList extends HookWidget {
  const SettingsCategoryList({
    required this.initialFocus,
    required this.onSelectCategory,
    super.key,
  });

  final SettingsCategory initialFocus;

  final ValueChanged<SettingsCategory> onSelectCategory;

  static Key rowKey(SettingsCategory category) =>
      Key('settings-row-${category.name}');

  static const aboutKey = Key('settings-row-about');

  @override
  Widget build(BuildContext context) {
    final rowNodes = useCategoryFocusNodes('settings row');

    useEffect(() {
      scheduleMicrotask(() {
        if (context.mounted) {
          focusFirstDescendant(rowNodes[initialFocus]!);
        }
      });

      return null;
    }, [rowNodes]);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            for (final category in SettingsCategory.values)
              _CategoryRow(
                key: rowKey(category),
                category: category,
                focusNode: rowNodes[category]!,
                onTap: () => onSelectCategory(category),
              ),
            FocusOnHover(
              child: SettingsTile(
                key: aboutKey,
                title: const Text('About NESd'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AboutDialog(),
                ),
                child: const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends HookWidget {
  const _CategoryRow({
    required this.category,
    required this.focusNode,
    required this.onTap,
    super.key,
  });

  final SettingsCategory category;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final focused = useState(false);

    final sections = sectionsOf(category);

    return FocusOnHover(
      focusNode: focusNode,
      onFocusChange: (value) => focused.value = value,
      child: SettingsTile(
        title: Text(category.title),
        subtitle: sections.length > 1
            ? Text(sections.map((s) => s.title).join(' · '))
            : null,
        onTap: onTap,
        child: Icon(
          Icons.chevron_right,
          size: 32,
          color: focused.value ? Theme.of(context).colorScheme.onPrimary : null,
        ),
      ),
    );
  }
}
