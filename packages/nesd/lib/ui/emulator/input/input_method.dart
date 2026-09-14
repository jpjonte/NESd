import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_method.g.dart';

const mouseMoveThreshold = 24.0;

enum InputMethod { keyboardMouse, gamepad, touch }

@immutable
class RecentInput {
  const RecentInput({required this.method, this.gamepadId});

  final InputMethod method;

  final String? gamepadId;
}

@Riverpod(keepAlive: true)
class RecentInputMethod extends _$RecentInputMethod {
  double _mouseTravel = 0;

  @override
  RecentInput build() {
    final subscription = ref
        .watch(gamepadInputMapperProvider)
        .stream
        .listen(_handleGamepadEvent);

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);

    ref.onDispose(() {
      unawaited(subscription.cancel());

      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _handlePointerEvent,
      );
    });

    return RecentInput(method: _initialMethod());
  }

  static InputMethod _initialMethod() => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => InputMethod.touch,
    _ => InputMethod.keyboardMouse,
  };

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _switchTo(InputMethod.keyboardMouse);
    }

    return false;
  }

  void _handleGamepadEvent(GamepadInputEvent event) {
    if (event.value.abs() > gamepadInputOnThreshold) {
      _switchTo(InputMethod.gamepad, gamepadId: event.gamepadId);
    }
  }

  void _handlePointerEvent(PointerEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.mouse || PointerDeviceKind.trackpad:
        _handleMouseEvent(event);
      case PointerDeviceKind.touch ||
          PointerDeviceKind.stylus ||
          PointerDeviceKind.invertedStylus:
        if (event is PointerDownEvent) {
          _switchTo(InputMethod.touch);
        }
      case PointerDeviceKind.unknown:
        break;
    }
  }

  void _handleMouseEvent(PointerEvent event) {
    if (event is PointerDownEvent ||
        event is PointerSignalEvent ||
        event is PointerPanZoomStartEvent) {
      _switchTo(InputMethod.keyboardMouse);

      return;
    }

    if (state.method == InputMethod.keyboardMouse) {
      return;
    }

    if (event is PointerHoverEvent || event is PointerMoveEvent) {
      _mouseTravel += event.delta.distance;

      if (_mouseTravel >= mouseMoveThreshold) {
        _switchTo(InputMethod.keyboardMouse);
      }
    }
  }

  void _switchTo(InputMethod method, {String? gamepadId}) {
    _mouseTravel = 0;

    final resolvedGamepadId = gamepadId ?? state.gamepadId;

    if (state.method == method && state.gamepadId == resolvedGamepadId) {
      return;
    }

    state = RecentInput(method: method, gamepadId: resolvedGamepadId);
  }
}
