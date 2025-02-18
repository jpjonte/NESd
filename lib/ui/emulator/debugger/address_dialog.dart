// raw strings are used to avoid escaping backslashes in regexes
// ignore_for_file: unnecessary_raw_strings

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AddressDialog extends HookWidget {
  const AddressDialog({required this.title, required this.onSubmitted});

  final String title;
  final Function(int) onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        onChanged: (_) {
          var text = controller.text;

          if (text.length > 4) {
            text = text.substring(0, 4);
          }

          if (text.contains(RegExp(r'[^0-9a-fA-F]'))) {
            text = text.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
          }

          controller
            ..value = TextEditingValue(text: text.toUpperCase())
            ..selection = TextSelection.collapsed(offset: text.length);
        },
        decoration: const InputDecoration(
          label: Text('Address'),
          hintText: '0000',
        ),
        onSubmitted: _submit,
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            _submit(controller.text);

            Navigator.of(context).pop();
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
