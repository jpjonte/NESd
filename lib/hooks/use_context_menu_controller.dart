import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

ContextMenuController useContextMenuController({
  VoidCallback? onRemove,
  List<Object?>? keys,
}) {
  return use(_ContextMenuControllerHook(onRemove: onRemove, keys: keys));
}

class _ContextMenuControllerHook extends Hook<ContextMenuController> {
  const _ContextMenuControllerHook({required this.onRemove, super.keys});

  final VoidCallback? onRemove;

  @override
  HookState<ContextMenuController, Hook<ContextMenuController>> createState() =>
      _ContextMenuControllerHookState();
}

class _ContextMenuControllerHookState
    extends HookState<ContextMenuController, _ContextMenuControllerHook> {
  late final controller = ContextMenuController(onRemove: hook.onRemove);

  @override
  ContextMenuController build(BuildContext context) => controller;

  // This won't be called in normal operation, so we ignore it
  // coverage:ignore-start
  @override
  String get debugLabel => 'useContextMenuController';
  // coverage:ignore-end
}
