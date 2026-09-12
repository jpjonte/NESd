import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/navigation/settings_category_list.dart';
import 'package:nesd/ui/settings/navigation/settings_category_page.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class StackedSettings extends HookConsumerWidget {
  const StackedSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(
      settingsNavigationProvider.select((s) => s.category),
    );
    final navigation = ref.read(settingsNavigationProvider.notifier);

    final returnTo = useState<SettingsCategory?>(null);

    final pendingEntry = useRef<String?>(null);

    final initialEntry = pendingEntry.value;
    pendingEntry.value = null;

    void backToList() {
      returnTo.value = navigation.category;
      navigation.category = null;
    }

    void selectEntry(SettingsEntryLocation target) {
      pendingEntry.value = target.id;
      navigation.reveal(target);
    }

    return PopScope(
      canPop: category == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          backToList();
        }
      },
      child: Actions(
        actions: {
          if (category != null) ...{
            PreviousTabIntent: CallbackAction<PreviousTabIntent>(
              onInvoke: (_) => navigation.step(-1),
            ),
            NextTabIntent: CallbackAction<NextTabIntent>(
              onInvoke: (_) => navigation.step(1),
            ),
          },
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: _slide,
          child: category == null
              ? SettingsCategoryList(
                  key: const ValueKey('settings-list'),
                  initialFocus: returnTo.value ?? SettingsCategory.general,
                  onSelectCategory: (selected) =>
                      navigation.category = selected,
                  onSelectEntry: selectEntry,
                )
              : SettingsCategoryPage(
                  key: ValueKey(category),
                  category: category,
                  initialEntry: initialEntry,
                ),
        ),
      ),
    );
  }

  static Widget _slide(Widget child, Animation<double> animation) {
    final fromRight = child.key is ValueKey<SettingsCategory>;

    final offset = Tween(
      begin: Offset(fromRight ? 1 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return SlideTransition(
      position: offset,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
