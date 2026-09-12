import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class SettingsSearchResults extends StatelessWidget {
  const SettingsSearchResults({
    required this.matches,
    required this.onSelect,
    super.key,
  });

  static Key rowKey(String entryId) => Key('settings-result-$entryId');

  static const emptyKey = Key('settings-results-empty');

  final List<SettingsEntryLocation> matches;
  final ValueChanged<SettingsEntryLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Padding(
        key: emptyKey,
        padding: const EdgeInsets.all(16),
        child: Text(
          'No matches',
          style: TextStyle(
            color: Theme.of(context).textTheme.labelMedium?.color,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final match in matches)
          _ResultRow(
            key: rowKey(match.id),
            title: match.entry.title,
            breadcrumb: match.breadcrumb,
            onTap: () => onSelect(match),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.breadcrumb,
    required this.onTap,
    super.key,
  });

  final String title;
  final String breadcrumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final focused = Focus.of(context).hasFocus;

          final color = focused ? theme.colorScheme.onPrimary : null;
          final breadcrumbColor = focused
              ? theme.colorScheme.onPrimary
              : theme.textTheme.labelMedium?.color;

          return InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontVariations: const [FontVariation.weight(700)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    breadcrumb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: breadcrumbColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
