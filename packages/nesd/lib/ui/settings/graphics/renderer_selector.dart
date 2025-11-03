import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class RendererSelector extends ConsumerWidget {
  const RendererSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.renderer),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) =>
              controller.rendererPreference = switch (setting) {
                RendererPreference.gpu => RendererPreference.auto,
                RendererPreference.cpu => RendererPreference.gpu,
                _ => setting,
              },
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) =>
              controller.rendererPreference = switch (setting) {
                RendererPreference.auto => RendererPreference.gpu,
                RendererPreference.gpu => RendererPreference.cpu,
                _ => setting,
              },
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Renderer'),
          adaptive: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: SegmentedButton<RendererPreference>(
                onSelectionChanged: (value) =>
                    controller.rendererPreference = value.first,
                segments: const [
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'Auto',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: RendererPreference.auto,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'GPU',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: RendererPreference.gpu,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'CPU',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: RendererPreference.cpu,
                  ),
                ],
                selected: {setting},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
