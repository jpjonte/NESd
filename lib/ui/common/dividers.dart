import 'package:flutter/material.dart';

class NesdVerticalDivider extends StatelessWidget {
  const NesdVerticalDivider({this.height = 16});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class DividedColumn extends StatelessWidget {
  const DividedColumn({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.divider = const NesdVerticalDivider(),
    super.key,
  });

  final List<Widget> children;

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  final CrossAxisAlignment crossAxisAlignment;

  final TextDirection? textDirection;

  final VerticalDirection verticalDirection;

  final TextBaseline? textBaseline;

  final Widget divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children:
          children
              .expand((child) => [child, divider])
              .take(children.length * 2 - 1)
              .toList(),
    );
  }
}
