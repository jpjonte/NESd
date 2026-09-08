import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_child.dart';

class NesdScaffold extends StatelessWidget {
  const NesdScaffold({this.appBar, this.backgroundColor, this.body, super.key});

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return FocusChild(
      autofocus: false,
      wrapAround: true,
      child: Scaffold(
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
      ),
    );
  }
}
