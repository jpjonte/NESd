import 'package:flutter/foundation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_navigation.g.dart';

@immutable
class SettingsNavigationState {
  const SettingsNavigationState({
    this.category,
    this.expandedGroups = const {},
  });

  final SettingsCategory? category;

  final Set<String> expandedGroups;

  @override
  bool operator ==(Object other) =>
      other is SettingsNavigationState &&
      other.category == category &&
      setEquals(other.expandedGroups, expandedGroups);

  @override
  int get hashCode =>
      Object.hash(category, Object.hashAllUnordered(expandedGroups));
}

@riverpod
class SettingsNavigation extends _$SettingsNavigation {
  @override
  SettingsNavigationState build() => const SettingsNavigationState();

  SettingsCategory? get category => state.category;

  set category(SettingsCategory? category) {
    state = SettingsNavigationState(
      category: category,
      expandedGroups: state.expandedGroups,
    );
  }

  void step(int delta) {
    const values = SettingsCategory.values;
    final index = values.indexOf(category ?? SettingsCategory.general);

    category = values[(index + delta) % values.length];
  }

  bool isExpanded(String groupId) => state.expandedGroups.contains(groupId);

  void toggleGroup(String groupId) {
    final expanded = {...state.expandedGroups};

    if (!expanded.remove(groupId)) {
      expanded.add(groupId);
    }

    state = SettingsNavigationState(
      category: state.category,
      expandedGroups: expanded,
    );
  }
}
