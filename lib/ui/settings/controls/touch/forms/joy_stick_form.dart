import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/controls/touch/forms/form_row.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class JoyStickForm extends ConsumerWidget {
  const JoyStickForm({
    required this.config,
    super.key,
  });

  final JoyStickConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    return DividedColumn(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderRow(
          label: 'Size',
          min: 20,
          max: 400,
          value: config.size,
          onChanged: (value) => controller.update(
            config.copyWith(
              size: value,
              innerSize: min(value, config.innerSize),
            ),
          ),
        ),
        SliderRow(
          label: 'Inner Size',
          min: 20,
          max: config.size,
          value: config.innerSize,
          onChanged: (value) =>
              controller.update(config.copyWith(innerSize: value)),
        ),
        SliderRow(
          label: 'Dead Zone',
          min: 0,
          max: 1,
          value: config.deadZone,
          onChanged: (value) =>
              controller.update(config.copyWith(deadZone: value)),
        ),
        ActionDropDownRow(
          label: 'Left Action',
          action: config.leftAction,
          onChanged: (action) =>
              controller.update(config.copyWith(leftAction: action)),
        ),
        ActionDropDownRow(
          label: 'Right Action',
          action: config.rightAction,
          onChanged: (action) =>
              controller.update(config.copyWith(rightAction: action)),
        ),
        ActionDropDownRow(
          label: 'Up Action',
          action: config.upAction,
          onChanged: (action) =>
              controller.update(config.copyWith(upAction: action)),
        ),
        ActionDropDownRow(
          label: 'Down Action',
          action: config.downAction,
          onChanged: (action) =>
              controller.update(config.copyWith(downAction: action)),
        ),
      ],
    );
  }
}
