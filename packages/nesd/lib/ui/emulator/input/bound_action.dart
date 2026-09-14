import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';

@immutable
class BoundAction {
  const BoundAction({
    required this.priority,
    required this.action,
    required this.bindingType,
    this.keys = const {},
  });

  final int priority;
  final InputAction action;
  final BindingType bindingType;

  final Set<LogicalKeyboardKey> keys;

  @override
  bool operator ==(Object other) =>
      other is BoundAction && other.action == action;

  @override
  int get hashCode => action.hashCode;
}
