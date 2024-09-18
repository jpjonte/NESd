import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/emulator/input/action.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';

class FormRow extends StatelessWidget {
  const FormRow({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class TextFieldRow extends HookWidget {
  const TextFieldRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);

    return FormRow(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  const ButtonRow({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return NesdButton(
      icon: Icon(icon),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class SliderRow extends StatelessWidget {
  const SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    super.key,
  });

  final String label;
  final double value;
  final void Function(double) onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return FormRow(
      label: label,
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}

class ActionDropDownRow extends StatelessWidget {
  const ActionDropDownRow({
    required this.action,
    required this.onChanged,
    this.label,
    super.key,
  });

  final String? label;
  final NesAction? action;
  final void Function(NesAction?) onChanged;

  @override
  Widget build(BuildContext context) {
    return FormRow(
      label: label ?? 'Action',
      child: DropdownButtonHideUnderline(
        child: InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(),
          ),
          child: DropdownButton<NesAction?>(
            value: action,
            onChanged: onChanged,
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            items: [
              const DropdownMenuItem(child: Text('None')),
              for (final action in allActions)
                DropdownMenuItem(
                  value: action,
                  child: Text(action.title),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
