import 'dart:async';

import 'package:flutter/material.dart';

void openDropdown(FocusNode node) {
  final context = node.context;

  if (context == null) {
    return;
  }

  scheduleMicrotask(() {
    if (context.mounted) {
      Actions.maybeInvoke(context, const ActivateIntent());
    }
  });
}

T? stepDropdownValue<T>(List<DropdownMenuItem<T>> items, T value, int delta) {
  final index = items.indexWhere((item) => item.value == value);
  final target = index + delta;

  if (index < 0 || target < 0 || target >= items.length) {
    return null;
  }

  return items[target].value;
}

class Dropdown<T> extends StatelessWidget {
  const Dropdown({
    required this.value,
    required this.onChanged,
    required this.items,
    this.focusNode,
    super.key,
  });

  final T value;
  final void Function(T?)? onChanged;
  final List<DropdownMenuItem<T>> items;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = Focus.of(context).hasFocus;

    final color = focused
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

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
          focusNode: focusNode,
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
