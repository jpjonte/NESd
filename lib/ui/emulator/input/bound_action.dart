import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';

@immutable
class BoundAction {
  const BoundAction({
    required this.priority,
    required this.action,
    required this.bindingType,
  });

  final int priority;
  final InputAction action;
  final BindingType bindingType;

  @override
  bool operator ==(Object other) =>
      other is BoundAction && other.action == action;

  @override
  int get hashCode => action.hashCode;
}
