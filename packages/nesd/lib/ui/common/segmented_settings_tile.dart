import 'package:flutter/material.dart';
import 'package:nesd/ui/common/settings_tile.dart';

class SegmentedSettingsTile<T> extends StatelessWidget {
  const SegmentedSettingsTile({
    required this.title,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final Widget title;
  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T value) label;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(value);

    void select(int target) {
      if (target != index) {
        onChanged(values[target]);
      }
    }

    return SettingsTile(
      title: title,
      adaptive: true,
      onTap: () => select((index + 1) % values.length),
      onDecrease: () => select(index > 0 ? index - 1 : index),
      onIncrease: () => select(index < values.length - 1 ? index + 1 : index),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            onSelectionChanged: (selected) => onChanged(selected.first),
            segments: [
              for (final candidate in values)
                ButtonSegment(
                  label: Center(
                    child: Text(
                      label(candidate),
                      style: const TextStyle(
                        fontVariations: [FontVariation.weight(700)],
                      ),
                    ),
                  ),
                  value: candidate,
                ),
            ],
            selected: {value},
          ),
        ),
      ),
    );
  }
}
