import 'package:flutter/material.dart';

class NesdVerticalDivider extends StatelessWidget {
  const NesdVerticalDivider({this.height = 16});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
