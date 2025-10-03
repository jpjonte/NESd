import 'package:flutter/material.dart';

class TabHeader extends StatelessWidget {
  const TabHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Text(
        title,
        style: const TextStyle(fontVariations: [FontVariation.weight(700)]),
      ),
    );
  }
}
