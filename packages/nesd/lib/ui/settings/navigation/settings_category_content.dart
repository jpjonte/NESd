import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/settings_section_header.dart';
import 'package:nesd/ui/settings/navigation/settings_group_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

typedef SectionKeys = Map<String, GlobalKey<SettingsSectionViewState>>;

SectionKeys createSectionKeys() => {
  for (final category in SettingsCategory.values)
    for (final section in sectionsOf(category))
      section.id: GlobalKey<SettingsSectionViewState>(debugLabel: section.id),
};

Future<void> scrollToSection(SectionKeys keys, String sectionId) async {
  final state = keys[sectionId]?.currentState;

  if (state == null) {
    return;
  }

  await Scrollable.ensureVisible(
    state.context,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
  );

  if (state.mounted) {
    state.focusFirstTile();
  }
}

class SettingsCategoryContent extends StatelessWidget {
  const SettingsCategoryContent({
    required this.category,
    required this.sectionKeys,
    super.key,
  });

  final SettingsCategory category;
  final SectionKeys sectionKeys;

  @override
  Widget build(BuildContext context) {
    final sections = sectionsOf(category);

    final showHeaders = sections.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections)
          SettingsSectionView(
            key: sectionKeys[section.id],
            section: section,
            showHeader: showHeaders,
          ),
      ],
    );
  }
}

class SettingsSectionView extends StatefulWidget {
  const SettingsSectionView({
    required this.section,
    required this.showHeader,
    super.key,
  });

  final SettingsSection section;
  final bool showHeader;

  @override
  State<SettingsSectionView> createState() => SettingsSectionViewState();
}

class SettingsSectionViewState extends State<SettingsSectionView> {
  final _focusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'settings section',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void focusFirstTile() => focusFirstDescendant(_focusNode);

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      skipTraversal: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader)
            SettingsSectionHeader(title: widget.section.title),
          for (final item in widget.section.items)
            switch (item) {
              SettingsEntry() => SettingsEntryView(entry: item),
              SettingsGroup() => SettingsGroupTile(group: item),
            },
        ],
      ),
    );
  }
}

class SettingsEntryView extends ConsumerWidget {
  const SettingsEntryView({required this.entry, super.key});

  final SettingsEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleWhen = entry.visibleWhen;

    if (visibleWhen != null && !visibleWhen(ref)) {
      return const SizedBox.shrink();
    }

    return entry.builder(context, ref);
  }
}
