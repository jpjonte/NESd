import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';

class SettingsSearchField extends HookWidget {
  const SettingsSearchField({
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  static const fieldKey = Key('settings-search-field');
  static const clearKey = Key('settings-search-clear');

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    final focused = useState(false);

    useEffect(() {
      if (controller.text != value) {
        controller.text = value;
      }

      return null;
    }, [value]);

    final colorScheme = Theme.of(context).colorScheme;
    final foreground = focused.value ? colorScheme.onPrimary : null;

    void clear() {
      controller.clear();

      onChanged('');
    }

    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (intent) {
            if (value.isNotEmpty) {
              clear();

              return null;
            }

            return Actions.maybeInvoke(context, intent);
          },
        ),
      },
      child: FocusOnHover(
        onFocusChange: (hasFocus) => focused.value = hasFocus,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          color: focused.value ? colorScheme.primary : colorScheme.surface,
          child: TextField(
            key: fieldKey,
            controller: controller,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmitted(),
            textInputAction: TextInputAction.search,
            cursorColor: foreground,
            style: TextStyle(color: foreground),
            decoration: InputDecoration(
              hintText: 'Search settings',
              hintStyle: TextStyle(
                color: focused.value ? Colors.grey[300] : null,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              prefixIcon: Icon(Icons.search, size: 18, color: foreground),
              suffixIcon: value.isEmpty
                  ? null
                  : IconButton(
                      key: clearKey,
                      onPressed: clear,
                      icon: Icon(Icons.close, size: 18, color: foreground),
                      tooltip: 'Clear search',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
