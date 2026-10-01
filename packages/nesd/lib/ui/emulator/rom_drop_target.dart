import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

class RomDropTarget extends HookConsumerWidget {
  const RomDropTarget({required this.child, super.key});

  static const highlightKey = Key('romDropHighlight');

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hovering = useState(false);

    if (!_dropSupported) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      enable: ModalRoute.isCurrentOf(context) ?? true,
      onDragEntered: (_) => hovering.value = true,
      onDragExited: (_) => hovering.value = false,
      onDragDone: (details) => unawaited(
        ref.read(nesControllerProvider).openDroppedRom(details.files),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (hovering.value)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: highlightKey,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    border: Border.all(color: colorScheme.primary, width: 4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

bool get _dropSupported =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
