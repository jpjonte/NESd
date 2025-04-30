import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/touch/forms/circle_button_form.dart';
import 'package:nesd/ui/settings/controls/touch/forms/d_pad_form.dart';
import 'package:nesd/ui/settings/controls/touch/forms/form_row.dart';
import 'package:nesd/ui/settings/controls/touch/forms/joy_stick_form.dart';
import 'package:nesd/ui/settings/controls/touch/forms/rectangle_button_form.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class TouchInputForm extends ConsumerWidget {
  const TouchInputForm({
    required this.config,
    required this.orientation,
    this.index,
    super.key,
  });

  final TouchInputConfig config;
  final Orientation orientation;
  final int? index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    return SingleChildScrollView(
      child: DividedColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Input',
                style: TextStyle(
                  fontSize: 20,
                  fontVariations: [FontVariation.weight(700)],
                ),
              ),
              IconButton(
                onPressed: () => controller.close(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          FormRow(
            label: 'Type',
            child: DropdownButtonHideUnderline(
              child: InputDecorator(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(),
                ),
                child: DropdownButton<TouchInputType>(
                  value: TouchInputType.forTouchInputConfig(config),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    if (TouchInputType.forTouchInputConfig(config) == value) {
                      return;
                    }

                    final newConfig = _switchType(config, value);

                    controller.update(newConfig);
                  },
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  items: const [
                    DropdownMenuItem(
                      value: TouchInputType.rectangleButton,
                      child: Text('Rectangle Button'),
                    ),
                    DropdownMenuItem(
                      value: TouchInputType.circleButton,
                      child: Text('Circle Button'),
                    ),
                    DropdownMenuItem(
                      value: TouchInputType.joyStick,
                      child: Text('Joy Stick'),
                    ),
                    DropdownMenuItem(
                      value: TouchInputType.dPad,
                      child: Text('D-Pad'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FormRow(
            label: 'X',
            child: Slider(
              value: config.x,
              min: -1,
              onChanged:
                  (value) => controller.update(config.copyWith(x: value)),
            ),
          ),
          FormRow(
            label: 'Y',
            child: Slider(
              value: config.y,
              min: -1,
              onChanged:
                  (value) => controller.update(config.copyWith(y: value)),
            ),
          ),
          FormRow(
            label: 'Type',
            child: Dropdown<BindingType>(
              value: config.bindingType,
              onChanged:
                  (value) => controller.update(
                    config.copyWith(bindingType: value ?? config.bindingType),
                  ),
              items: const [
                DropdownMenuItem(value: BindingType.hold, child: Text('Hold')),
                DropdownMenuItem(
                  value: BindingType.toggle,
                  child: Text('Toggle'),
                ),
              ],
            ),
          ),
          switch (config) {
            final RectangleButtonConfig config => RectangleButtonForm(
              config: config,
            ),
            final CircleButtonConfig config => CircleButtonForm(config: config),
            final JoyStickConfig config => JoyStickForm(config: config),
            final DPadConfig config => DPadForm(config: config),
          },
          ButtonRow(
            label: index == null ? 'Add' : 'Delete',
            icon: index == null ? Icons.add : Icons.delete,
            onPressed: () {
              if (index == null) {
                controller.save(orientation);
              } else {
                controller.delete();
              }
            },
          ),
        ],
      ),
    );
  }

  TouchInputConfig _switchType(TouchInputConfig config, TouchInputType type) {
    return switch (type) {
      TouchInputType.rectangleButton => _toRectangleButton(config),
      TouchInputType.circleButton => _toCircleButton(config),
      TouchInputType.joyStick => _toJoyStick(config),
      TouchInputType.dPad => _toDPad(config),
    };
  }

  RectangleButtonConfig _toRectangleButton(TouchInputConfig config) {
    return switch (config) {
      final RectangleButtonConfig config => config,
      final CircleButtonConfig config => RectangleButtonConfig(
        x: config.x,
        y: config.y,
        width: config.size,
        height: config.size,
        label: config.label,
        action: config.action,
      ),
      final JoyStickConfig config => RectangleButtonConfig(
        x: config.x,
        y: config.y,
        width: config.size,
        height: config.size,
      ),
      final DPadConfig config => RectangleButtonConfig(
        x: config.x,
        y: config.y,
        width: config.size,
        height: config.size,
      ),
    };
  }

  CircleButtonConfig _toCircleButton(TouchInputConfig config) {
    return switch (config) {
      final RectangleButtonConfig config => CircleButtonConfig(
        x: config.x,
        y: config.y,
        size: min(config.width, config.height),
        label: config.label,
        action: config.action,
      ),
      final CircleButtonConfig config => config,
      final JoyStickConfig config => CircleButtonConfig(
        x: config.x,
        y: config.y,
        size: config.size,
      ),
      final DPadConfig config => CircleButtonConfig(
        x: config.x,
        y: config.y,
        size: config.size,
      ),
    };
  }

  JoyStickConfig _toJoyStick(TouchInputConfig config) {
    return switch (config) {
      final RectangleButtonConfig config => JoyStickConfig(
        x: config.x,
        y: config.y,
        size: min(config.width, config.height),
        innerSize: min(config.width, config.height) / 2,
      ),
      final CircleButtonConfig config => JoyStickConfig(
        x: config.x,
        y: config.y,
        size: config.size,
        innerSize: config.size / 2,
      ),
      final JoyStickConfig config => config,
      final DPadConfig config => JoyStickConfig(
        x: config.x,
        y: config.y,
        size: config.size,
        innerSize: config.size / 2,
        deadZone: config.deadZone,
        upAction: config.upAction,
        downAction: config.downAction,
        leftAction: config.leftAction,
        rightAction: config.rightAction,
      ),
    };
  }

  DPadConfig _toDPad(TouchInputConfig config) {
    return switch (config) {
      final RectangleButtonConfig config => DPadConfig(
        x: config.x,
        y: config.y,
        size: min(config.width, config.height),
      ),
      final CircleButtonConfig config => DPadConfig(
        x: config.x,
        y: config.y,
        size: config.size,
      ),
      final JoyStickConfig config => DPadConfig(
        x: config.x,
        y: config.y,
        size: config.size,
        deadZone: config.deadZone,
        upAction: config.upAction,
        downAction: config.downAction,
        leftAction: config.leftAction,
        rightAction: config.rightAction,
      ),
      final DPadConfig config => config,
    };
  }
}
