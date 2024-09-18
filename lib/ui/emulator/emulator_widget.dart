import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/debug_overlay.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/settings/settings.dart';

class EmulatorWidget extends ConsumerWidget {
  const EmulatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Stack(
      children: [
        const FrameBufferStreamBuilder(),
        if (settings.showDebugOverlay) const DebugOverlay(),
        if (settings.showTouchControls) const TouchControlsBuilder(),
      ],
    );
  }
}
