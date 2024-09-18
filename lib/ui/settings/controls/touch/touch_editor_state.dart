import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'touch_editor_state.freezed.dart';
part 'touch_editor_state.g.dart';

@freezed
class TouchEditorState with _$TouchEditorState {
  const factory TouchEditorState({
    @Default(true) bool showHint,
    @Default(null) int? editingIndex,
    @Default(null) Orientation? editingOrientation,
    @Default(null) TouchInputConfig? editingConfig,
  }) = _TouchEditorState;
}

@riverpod
class TouchEditorNotifier extends _$TouchEditorNotifier {
  @override
  TouchEditorState build() {
    return const TouchEditorState();
  }

  void hideHint() {
    state = state.copyWith(showHint: false);
  }

  void add(Orientation orientation) {
    state = state.copyWith(
      editingConfig:
          const RectangleButtonConfig(action: controller1A, x: 0, y: 0),
      editingOrientation: orientation,
    );
  }

  void close() {
    state = state.copyWith(editingIndex: null, editingConfig: null);
  }

  void update(TouchInputConfig item) {
    final orientation = state.editingOrientation;
    final index = state.editingIndex;

    state = state.copyWith(editingConfig: item);

    if (index == null || orientation == null) {
      return;
    }

    ref
        .read(settingsControllerProvider.notifier)
        .setTouchInputConfig(orientation, index, item);
  }

  void reset(Orientation orientation) {
    ref
        .read(settingsControllerProvider.notifier)
        .resetTouchInputConfigs(orientation);
  }

  void edit(Orientation orientation, Size viewport, Offset offset) {
    final controller = ref.read(settingsControllerProvider.notifier);

    final result = controller.touchInputConfigAtPosition(
      orientation,
      viewport,
      offset,
    );

    if (result == null) {
      return;
    }

    final (index, item) = result;

    state = state.copyWith(
      editingIndex: index,
      editingOrientation: orientation,
      editingConfig: item,
    );
  }

  void save(Orientation orientation) {
    final config = state.editingConfig;

    if (config == null) {
      return;
    }

    ref
        .read(settingsControllerProvider.notifier)
        .addTouchInputConfig(orientation, config);

    state = state.copyWith(editingIndex: null, editingConfig: null);
  }

  void delete() {
    final index = state.editingIndex;

    if (index == null) {
      return;
    }

    final orientation = state.editingOrientation;

    if (orientation == null) {
      return;
    }

    ref
        .read(settingsControllerProvider.notifier)
        .removeTouchInputConfig(orientation, index);

    state = state.copyWith(editingIndex: null, editingConfig: null);
  }
}

@riverpod
class TouchEditorMoveIndex extends _$TouchEditorMoveIndex {
  @override
  int? build() {
    return null;
  }

  int? get index => state;

  set index(int? index) => state = index;

  ui.Rect? startMoving(Orientation orientation, Size viewport, Offset offset) {
    final controller = ref.read(settingsControllerProvider.notifier);

    final result = controller.touchInputConfigAtPosition(
      orientation,
      viewport,
      offset,
    );

    if (result == null) {
      return null;
    }

    final (index, item) = result;

    state = index;

    return item.boundingBox(viewport);
  }

  void updateMovement(Orientation orientation, Size viewport, Offset offset) {
    final index = state;

    if (index == null) {
      return;
    }

    final normalized = _normalize(
      viewport,
      offset,
    );

    final controller = ref.read(settingsControllerProvider.notifier);

    final config =
        controller.touchInputConfigForOrientation(orientation, index);

    final newConfig = config.copyWith(
      x: normalized.dx,
      y: normalized.dy,
    );

    controller.setTouchInputConfig(orientation, index, newConfig);
  }

  void stopMoving() {
    state = null;
  }

  Offset _normalize(Size viewport, Offset offset) {
    final center = viewport.center(Offset.zero);
    final relative = offset - center;

    return Offset(relative.dx / center.dx, relative.dy / center.dy);
  }
}
