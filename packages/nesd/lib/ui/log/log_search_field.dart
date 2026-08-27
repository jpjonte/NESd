import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LogSearchField extends HookWidget {
  const LogSearchField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  static const clearKey = Key('logSearchClear');

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);

    useEffect(() {
      if (controller.text != value) {
        controller.text = value;
      }

      return null;
    }, [value]);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                key: clearKey,
                onPressed: () {
                  controller.clear();

                  onChanged('');
                },
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear search',
              ),
      ),
    );
  }
}
