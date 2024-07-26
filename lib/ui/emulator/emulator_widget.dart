import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/touch_controls.dart';
import 'package:nesd/ui/settings/settings.dart';

class EmulatorWidget extends ConsumerWidget {
  const EmulatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(child: DisplayWidget()),
      ],
    );
  }
}
