import 'package:flutter/material.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binder.dart';

class BindingTile extends StatelessWidget {
  const BindingTile({
    required this.action,
    super.key,
  });

  final NesAction action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(action.title),
      trailing: Binder(action: action),
    );
  }
}
