import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class SettingsCategoryPage extends HookWidget {
  const SettingsCategoryPage({required this.category, super.key});

  final SettingsCategory category;

  static Key chipKey(String sectionId) => Key('settings-chip-$sectionId');

  @override
  Widget build(BuildContext context) {
    final sections = sectionsOf(category);

    final sectionKeys = useMemoized(createSectionKeys);
    final entryKeys = useMemoized(createEntryKeys);

    final contentFocus = useFocusNode(
      skipTraversal: true,
      debugLabel: 'settings page content',
    );

    useEffect(() {
      scheduleMicrotask(() {
        if (context.mounted) {
          focusFirstDescendant(contentFocus);
        }
      });

      return null;
    }, const []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (sections.length > 1)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  for (final section in sections)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FocusOnHover(
                        child: ActionChip(
                          key: chipKey(section.id),
                          label: Text(section.title),
                          onPressed: () => unawaited(
                            scrollToSection(sectionKeys, section.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Focus(
              focusNode: contentFocus,
              skipTraversal: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: SettingsCategoryContent(
                  category: category,
                  sectionKeys: sectionKeys,
                  entryKeys: entryKeys,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
