import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmationDialog extends ConsumerWidget {
  const ConfirmationDialog({
    this.title,
    this.content,
    this.confirmLabel,
    this.cancelLabel,
    super.key,
  });

  final Widget? title;
  final Widget? content;

  final Widget? confirmLabel;
  final Widget? cancelLabel;

  static Future<bool?> show(
    BuildContext context, {
    Widget? title,
    Widget? content,
    Widget? confirmLabel,
    Widget? cancelLabel,
  }) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            content: content,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: content,
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: cancelLabel ?? const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: confirmLabel ?? const Text('OK'),
        ),
      ],
    );
  }
}
