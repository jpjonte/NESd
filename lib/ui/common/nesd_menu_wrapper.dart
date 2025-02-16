import 'package:flutter/material.dart';

class NesdMenuWrapper extends StatelessWidget {
  const NesdMenuWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: 800,
        maxHeight: mediaQuery.size.height,
      ),
      padding: const EdgeInsets.all(8.0),
      child: child,
    );
  }
}
