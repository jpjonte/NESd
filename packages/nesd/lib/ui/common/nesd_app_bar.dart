import 'package:flutter/material.dart';

class NesdAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NesdAppBar({this.title, this.actions, super.key});

  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canDismiss = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return AppBar(
      leading: canDismiss
          ? FocusTraversalGroup(
              descendantsAreTraversable: false,
              child: const BackButton(),
            )
          : null,
      title: title,
      actions: actions,
    );
  }
}
