import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/fuzzy_matcher.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

List<SettingsEntryLocation> searchSettings(String query) {
  if (query.trim().isEmpty) {
    return const [];
  }

  final scored = <(double, int, SettingsEntryLocation)>[];

  for (final (index, location) in settingsEntryLocations.indexed) {
    final score = fuzzyScore(query, location.searchText);

    if (score != null) {
      scored.add((score, index, location));
    }
  }

  scored.sort((a, b) {
    final byScore = b.$1.compareTo(a.$1);

    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });

  return [for (final (_, _, location) in scored) location];
}

List<SettingsEntryLocation> visibleSettingsMatches(
  WidgetRef ref,
  String query,
) => [
  for (final match in searchSettings(query))
    if (match.entry.visibleWhen?.call(ref) ?? true) match,
];
