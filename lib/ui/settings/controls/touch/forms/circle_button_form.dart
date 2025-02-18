import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/controls/touch/forms/form_row.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class CircleButtonForm extends ConsumerWidget {
  const CircleButtonForm({required this.config, super.key});

  final CircleButtonConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    return DividedColumn(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderRow(
          label: 'Size',
          value: config.size,
          min: 20,
          max: 400,
          onChanged: (value) => controller.update(config.copyWith(size: value)),
        ),
        TextFieldRow(
          label: 'Label',
          value: config.label,
          onChanged:
              (label) => controller.update(config.copyWith(label: label)),
        ),
        ActionDropDownRow(
          action: config.action,
          onChanged:
              (action) => controller.update(config.copyWith(action: action)),
        ),
      ],
    );
  }
}
