import 'package:flutter/material.dart' hide AboutDialog;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/search/settings_search.dart';
import 'package:nesd/ui/settings/search/settings_search_field.dart';
import 'package:nesd/ui/settings/search/settings_search_results.dart';

class SettingsNavPane extends ConsumerWidget {
  const SettingsNavPane({
    required this.categoryFocusNodes,
    required this.onSelectCategory,
    required this.onSelectSection,
    required this.onSelectEntry,
    super.key,
  });

  final Map<SettingsCategory, FocusNode> categoryFocusNodes;

  final ValueChanged<SettingsCategory> onSelectCategory;
  final void Function(SettingsCategory category, String sectionId)
  onSelectSection;
  final ValueChanged<SettingsEntryLocation> onSelectEntry;

  static const width = 240.0;

  static Key itemKey(SettingsCategory category) =>
      Key('settings-nav-${category.name}');

  static Key sectionKey(String sectionId) =>
      Key('settings-nav-section-$sectionId');

  static const aboutKey = Key('settings-nav-about');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(settingsNavigationProvider.select((s) => s.category)) ??
        SettingsCategory.general;
    final query = ref.watch(settingsNavigationProvider.select((s) => s.query));
    final navigation = ref.read(settingsNavigationProvider.notifier);

    final matches = visibleSettingsMatches(ref, query);
    final searching = query.trim().isNotEmpty;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SettingsSearchField(
            value: query,
            onChanged: (value) => navigation.query = value,
            onSubmitted: () {
              if (matches.isNotEmpty) {
                onSelectEntry(matches.first);
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: searching
                  ? SettingsSearchResults(
                      matches: matches,
                      onSelect: onSelectEntry,
                    )
                  : Column(
                      children: [
                        for (final category in SettingsCategory.values) ...[
                          SettingsNavItem(
                            key: itemKey(category),
                            focusNode: categoryFocusNodes[category],
                            icon: category.icon,
                            title: category.title,
                            selected: category == selected,
                            onTap: () => onSelectCategory(category),
                          ),
                          if (sectionsOf(category).length > 1)
                            for (final section in sectionsOf(category))
                              SettingsNavItem(
                                key: sectionKey(section.id),
                                title: section.title,
                                indent: true,
                                onTap: () =>
                                    onSelectSection(category, section.id),
                              ),
                        ],
                        SettingsNavItem(
                          key: aboutKey,
                          icon: Icons.info_outline,
                          title: 'About NESd',
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => const AboutDialog(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsNavItem extends StatelessWidget {
  const SettingsNavItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.indent = false,
    this.focusNode,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool indent;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final focused = Focus.of(context).hasFocus;

          final color = switch ((focused, selected)) {
            (true, _) => theme.colorScheme.onPrimary,
            (false, true) => theme.colorScheme.primary,
            (false, false) => null,
          };

          return InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: EdgeInsets.only(left: indent ? 48 : 16, right: 16),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: indent ? 14 : 15,
                          fontVariations: [
                            FontVariation.weight(indent ? 400 : 700),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
