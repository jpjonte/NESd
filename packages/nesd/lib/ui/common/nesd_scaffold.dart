import 'package:flutter/material.dart';

class NesdScaffold extends StatelessWidget {
  const NesdScaffold({this.appBar, this.backgroundColor, this.body, super.key});

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        child: body ?? const SizedBox(),
      ),
    );
  }
}
