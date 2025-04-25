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
    return DropdownButtonHideUnderline(
      child: InputDecorator(
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(),
        ),
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          items: items,
        ),
      ),
    );
  }
}
