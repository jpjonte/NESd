import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class RegionSelector extends ConsumerWidget {
  const RegionSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.region),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => controller.region = switch (setting) {
            null => setting,
            Region.ntsc => null,
            Region.pal => Region.ntsc,
          },
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => controller.region = switch (setting) {
            null => Region.ntsc,
            Region.ntsc => Region.pal,
            Region.pal => setting,
          },
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Console Region'),
          adaptive: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: SegmentedButton<Region?>(
                onSelectionChanged: (value) => controller.region = value.first,
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
                    value: null,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'NTSC',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: Region.ntsc,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'PAL',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: Region.pal,
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
