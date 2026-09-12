import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/settings_section_header.dart';
import 'package:nesd/ui/settings/navigation/settings_group_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

typedef SectionKeys = Map<String, GlobalKey<SettingsSectionViewState>>;

typedef EntryKeys = Map<String, GlobalKey<SettingsEntryViewState>>;

SectionKeys createSectionKeys() => {
  for (final category in SettingsCategory.values)
    for (final section in sectionsOf(category))
      section.id: GlobalKey<SettingsSectionViewState>(debugLabel: section.id),
};

EntryKeys createEntryKeys() => {
  for (final location in settingsEntryLocations)
    location.id: GlobalKey<SettingsEntryViewState>(debugLabel: location.id),
};

Future<void> _scrollToAndFocus(
  State<StatefulWidget> state,
  VoidCallback focus,
) async {
  await Scrollable.ensureVisible(
    state.context,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
  );

  if (state.mounted) {
    focus();
  }
}

Future<void> scrollToSection(SectionKeys keys, String sectionId) async {
  final state = keys[sectionId]?.currentState;

  if (state == null) {
    return;
  }

  await _scrollToAndFocus(state, state.focusFirstTile);
}

Future<void> scrollToEntry(EntryKeys keys, String entryId) async {
  final state = keys[entryId]?.currentState;

  if (state == null) {
    return;
  }

  await _scrollToAndFocus(state, state.focus);
}

class SettingsCategoryContent extends StatelessWidget {
  const SettingsCategoryContent({
    required this.category,
    required this.sectionKeys,
    required this.entryKeys,
    super.key,
  });

  final SettingsCategory category;
  final SectionKeys sectionKeys;
  final EntryKeys entryKeys;

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
            entryKeys: entryKeys,
          ),
      ],
    );
  }
}

class SettingsSectionView extends StatefulWidget {
  const SettingsSectionView({
    required this.section,
    required this.showHeader,
    required this.entryKeys,
    super.key,
  });

  final SettingsSection section;
  final bool showHeader;
  final EntryKeys entryKeys;

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
    final section = widget.section;

    return Focus(
      focusNode: _focusNode,
      skipTraversal: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) SettingsSectionHeader(title: section.title),
          for (final item in section.items)
            switch (item) {
              SettingsEntry() => SettingsEntryView(
                key: widget.entryKeys[settingsEntryId(section.id, item)],
                entry: item,
              ),
              SettingsGroup() => SettingsGroupTile(
                group: item,
                entryKeys: widget.entryKeys,
              ),
            },
        ],
      ),
    );
  }
}

class SettingsEntryView extends ConsumerStatefulWidget {
  const SettingsEntryView({required this.entry, super.key});

  final SettingsEntry entry;

  @override
  ConsumerState<SettingsEntryView> createState() => SettingsEntryViewState();
}

class SettingsEntryViewState extends ConsumerState<SettingsEntryView> {
  final _focusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'settings entry',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void focus() => focusFirstDescendant(_focusNode);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final visibleWhen = entry.visibleWhen;

    if (visibleWhen != null && !visibleWhen(ref)) {
      return const SizedBox.shrink();
    }

    return Focus(
      focusNode: _focusNode,
      skipTraversal: true,
      child: entry.builder(context, ref),
    );
  }
}
