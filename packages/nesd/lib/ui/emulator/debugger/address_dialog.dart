// raw strings are used to avoid escaping backslashes in regexes
// ignore_for_file: unnecessary_raw_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AddressDialog extends HookWidget {
  const AddressDialog({required this.title, required this.onSubmitted});

  final String title;
  final Function(int) onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    final navigator = Navigator.of(context);

    return AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        controller: controller,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9a-fA-F]*')),
          TextInputFormatter.withFunction(
            (_, newValue) =>
                newValue.copyWith(text: newValue.text.toUpperCase()),
          ),
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: const InputDecoration(
          label: Text('Address'),
          hintText: '0000',
        ),
        onSubmitted: (text) {
          _submit(text);

          navigator.pop();
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => navigator.pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            _submit(controller.text);

            navigator.pop();
          },
        ),
      ],
    );
  }

  void _submit(String text) {
    final address = int.tryParse(text, radix: 16);

    if (address != null) {
      onSubmitted(address);
    }
  }
}
