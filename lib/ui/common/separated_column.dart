import 'package:flutter/material.dart';

class SeparatedColumn extends StatelessWidget {
  const SeparatedColumn({
    required this.children,
    this.separatorBuilder,
    super.key,
  });

  final List<Widget> children;
  final Widget Function(int index)? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          children.asMap().entries.expand((entry) {
            final index = entry.key;
            final child = entry.value;

            return [
              if (separatorBuilder case final builder? when index > 0)
                builder(index - 1),
              child,
            ];
          }).toList(),
    );
  }
}
