import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_mode.dart';
import 'package:nesd/ui/settings/settings.dart';

class ScreenshotModeDropdown extends HookConsumerWidget {
  const ScreenshotModeDropdown({this.expand = false, super.key});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.screenshotMode),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final dropdownFocus = useFocusNode(skipTraversal: true);

    const items = [
      DropdownMenuItem(value: ScreenshotMode.raw, child: Text('Raw frame')),
      DropdownMenuItem(
        value: ScreenshotMode.displayed,
        child: Text('As displayed'),
      ),
    ];

    void step(int delta) {
      final next = stepDropdownValue(items, controller.screenshotMode, delta);

      if (next != null) {
        controller.screenshotMode = next;
      }
    }

    return FocusOnHover(
      child: SettingsTile(
        title: const Text('Screenshots'),
        adaptive: true,
        onTap: () => openDropdown(dropdownFocus),
        onDecrease: () => step(-1),
        onIncrease: () => step(1),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<ScreenshotMode>(
            focusNode: dropdownFocus,
            value: setting,
            onChanged: (value) =>
                controller.screenshotMode = value ?? ScreenshotMode.raw,
            items: items,
          ),
        ),
      ),
    );
  }
}
