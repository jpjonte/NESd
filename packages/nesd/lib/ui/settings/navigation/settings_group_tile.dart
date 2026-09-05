import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class SettingsGroupTile extends HookConsumerWidget {
  const SettingsGroupTile({required this.group, super.key});

  final SettingsGroup group;

  static Key headerKey(String groupId) => Key('settings-group-$groupId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(
      settingsNavigationProvider.select(
        (s) => s.expandedGroups.contains(group.id),
      ),
    );
    final navigation = ref.read(settingsNavigationProvider.notifier);

    final focused = useState(false);

    final iconColor = focused.value
        ? Theme.of(context).colorScheme.onPrimary
        : null;

    return Column(
      children: [
        FocusOnHover(
          onFocusChange: (value) => focused.value = value,
          child: SettingsTile(
            key: headerKey(group.id),
            title: Text('${group.title} (${group.entries.length})'),
            onTap: () => navigation.toggleGroup(group.id),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 32,
                color: iconColor,
              ),
            ),
          ),
        ),
        if (expanded)
          for (final entry in group.entries) SettingsEntryView(entry: entry),
      ],
    );
  }
}
