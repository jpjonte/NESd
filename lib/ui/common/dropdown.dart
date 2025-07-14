import 'package:flutter/material.dart';

class Dropdown<T> extends StatelessWidget {
  const Dropdown({
    required this.value,
    required this.onChanged,
    required this.items,
    super.key,
  });

  final T value;
  final void Function(T?)? onChanged;
  final List<DropdownMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = Focus.of(context).hasFocus;

    final color =
        focused ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final border = theme.inputDecorationTheme.border!.borderSide;

    return DropdownButtonHideUnderline(
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderSide: border.copyWith(color: color),
          ),
        ),
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          style: DefaultTextStyle.of(context).style.copyWith(
            color: color,
            fontVariations: const [FontVariation.weight(700)],
          ),
          items: items,
        ),
      ),
    );
  }
}
