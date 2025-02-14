import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/controls/reset_bindings_button.dart';
import 'package:nesd/ui/settings/controls/show_touch_controls_switch.dart';
import 'package:nesd/ui/settings/controls/touch_editor_button.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/settings_tab.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'controls_settings.g.dart';

class ControlsSettings extends StatelessWidget {
  const ControlsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTab(
      index: 3,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ShowTouchControlsSwitch(),
            const ResetBindingsButton(),
            const TouchEditorButton(),
            const ProfileSelectionHeader(),
            for (final action in allActions) BindingTile(action: action),
          ],
        ),
      ),
    );
  }
}

@riverpod
int maxIndex(Ref ref) {
  final bindings = ref.watch(
    settingsControllerProvider.select((s) => s.bindings),
  );

  return bindings.values.fold(
    0,
    (acc, inputs) => max(acc, inputs.length - 1),
  );
}

@riverpod
class ProfileIndex extends _$ProfileIndex {
  @override
  int build() {
    final subscription = ref.listen(
      maxIndexProvider,
      (_, m) => maxIndex = m,
      fireImmediately: true,
    );

    ref.onDispose(subscription.close);

    return 0;
  }

  int maxIndex = 0;

  void previous() {
    state = max(0, state - 1);
  }

  void next() {
    state = min(state + 1, maxIndex + 1);
  }
}

class ProfileSelectionHeader extends ConsumerWidget {
  const ProfileSelectionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexController = ref.watch(profileIndexProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (_) => indexController.previous(),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (_) => indexController.next(),
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          onTap: () {},
          child: const SizedBox(
            width: 324,
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PreviousProfileButton(),
                SizedBox(width: 8),
                CurrentProfileHeader(),
                SizedBox(width: 8),
                NextProfileButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurrentProfileHeader extends ConsumerWidget {
  const CurrentProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(profileIndexProvider);

    return Center(
      child: Text(
        'Profile ${index + 1}',
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        ),
      ),
    );
  }
}

class PreviousProfileButton extends ConsumerWidget {
  const PreviousProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(profileIndexProvider);
    final indexController = ref.read(profileIndexProvider.notifier);

    return SizedBox(
      width: 40,
      height: 40,
      child: index > 0
          ? IconButton(
              onPressed: indexController.previous,
              icon: const Icon(Icons.keyboard_arrow_left),
            )
          : null,
    );
  }
}

class NextProfileButton extends ConsumerWidget {
  const NextProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(profileIndexProvider);
    final indexController = ref.read(profileIndexProvider.notifier);

    final maxIndex = ref.watch(maxIndexProvider);

    Widget? child;

    if (index <= maxIndex) {
      child = IconButton(
        onPressed: indexController.next,
        icon: Icon(
          index == maxIndex ? Icons.add : Icons.keyboard_arrow_right,
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: child,
    );
  }
}
