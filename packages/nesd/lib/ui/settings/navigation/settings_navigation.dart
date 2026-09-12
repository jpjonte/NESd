import 'package:flutter/foundation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_navigation.g.dart';

@immutable
class SettingsNavigationState {
  const SettingsNavigationState({
    this.category,
    this.expandedGroups = const {},
    this.query = '',
  });

  final SettingsCategory? category;

  final Set<String> expandedGroups;

  final String query;

  @override
  bool operator ==(Object other) =>
      other is SettingsNavigationState &&
      other.category == category &&
      setEquals(other.expandedGroups, expandedGroups) &&
      other.query == query;

  @override
  int get hashCode =>
      Object.hash(category, Object.hashAllUnordered(expandedGroups), query);
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
      query: state.query,
    );
  }

  String get query => state.query;

  set query(String query) {
    state = SettingsNavigationState(
      category: state.category,
      expandedGroups: state.expandedGroups,
      query: query,
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
      query: state.query,
    );
  }

  void reveal(SettingsEntryLocation target) {
    final group = target.group;

    state = SettingsNavigationState(
      category: target.category,
      expandedGroups: {...state.expandedGroups, if (group != null) group.id},
      query: state.query,
    );
  }
}
