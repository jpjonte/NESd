import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/segmented_settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class RendererSelector extends ConsumerWidget {
  const RendererSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.renderer),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SegmentedSettingsTile<RendererPreference>(
        title: const Text('Renderer'),
        values: const [
          RendererPreference.auto,
          RendererPreference.gpu,
          RendererPreference.cpu,
        ],
        value: setting,
        onChanged: (value) => controller.rendererPreference = value,
        label: (value) => switch (value) {
          RendererPreference.auto => 'Auto',
          RendererPreference.gpu => 'GPU',
          RendererPreference.cpu => 'CPU',
        },
      ),
    );
  }
}
