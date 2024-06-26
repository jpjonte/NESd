import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/input/action/all_actions.dart';
import 'package:nes/ui/settings/controls/binding_tile.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'controls_settings.g.dart';

class ControlsSettings extends HookConsumerWidget {
  const ControlsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const ProfileSelectionHeader(),
        for (final action in allActions) BindingTile(action: action),
      ],
    );
  }
}

@riverpod
int maxIndex(MaxIndexRef ref) {
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

class ProfileSelectionHeader extends StatelessWidget {
  const ProfileSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      trailing: SizedBox(
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
            SizedBox(width: 44),
          ],
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
