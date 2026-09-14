import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/segmented_settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class RegionSelector extends ConsumerWidget {
  const RegionSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.region),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SegmentedSettingsTile<Region?>(
        title: const Text('Console Region'),
        values: const [null, Region.ntsc, Region.pal],
        value: setting,
        onChanged: (value) => controller.region = value,
        label: (value) => switch (value) {
          null => 'Auto',
          Region.ntsc => 'NTSC',
          Region.pal => 'PAL',
        },
      ),
    );
  }
}
