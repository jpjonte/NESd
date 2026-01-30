import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';

class TouchEditorButton extends ConsumerWidget {
  const TouchEditorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final touchControlsActive = ref.watch(
      settingsControllerProvider.select((s) => s.showTouchControls),
    );

    return FocusOnHover(
      child: ButtonSettingsTile(
        title: const Text('Edit touch controls'),
        onPressed: touchControlsActive
            ? () => ref.read(routerProvider).navigate(const TouchEditorRoute())
            : null,
      ),
    );
  }
}
