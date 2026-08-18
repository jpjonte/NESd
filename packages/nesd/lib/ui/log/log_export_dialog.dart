import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Future<bool?> showLogExportDialog(BuildContext context) =>
    showDialog<bool>(context: context, builder: (_) => const LogExportDialog());

class LogExportDialog extends HookWidget {
  const LogExportDialog({super.key});

  static const includeContextKey = Key('logExportIncludeContext');
  static const saveKey = Key('logExportSave');
  static const cancelKey = Key('logExportCancel');

  @override
  Widget build(BuildContext context) {
    final includeContext = useState(true);

    return AlertDialog(
      title: const Text('Save log'),
      content: SwitchListTile(
        key: includeContextKey,
        title: const Text('Include context'),
        subtitle: const Text('JSON context and stack traces'),
        value: includeContext.value,
        onChanged: (value) => includeContext.value = value,
      ),
      actions: [
        TextButton(
          key: cancelKey,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: saveKey,
          onPressed: () => Navigator.of(context).pop(includeContext.value),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
