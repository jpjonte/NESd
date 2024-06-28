import 'package:flutter/material.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binder.dart';
import 'package:nes/ui/settings/controls/binding.dart';

class BindingTile extends StatelessWidget {
  const BindingTile({
    required this.action,
    required this.binding,
    super.key,
  });

  final NesAction action;
  final InputCombination? binding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(action.title),
      trailing: Binder(action: action, binding: binding),
    );
  }
}
