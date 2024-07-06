import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/common/focus_child.dart';
import 'package:nes/ui/settings/settings_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(settingsTabIndexProvider);

    return FocusChild(
      autofocus: currentIndex == index,
      child: child,
    );
  }
}
