import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/settings.dart';

class UpscalingFilterSwitch extends StatelessWidget {
  const UpscalingFilterSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VideoFilterSwitch(
      filter: VideoFilter.xbr,
      title: 'Upscaling (xBR)',
    );
  }
}

class SmoothingFilterSwitch extends StatelessWidget {
  const SmoothingFilterSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VideoFilterSwitch(
      filter: VideoFilter.smooth,
      title: 'Smoothing',
    );
  }
}

class CrtFilterSwitch extends StatelessWidget {
  const CrtFilterSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VideoFilterSwitch(
      filter: VideoFilter.crt,
      title: 'CRT effect',
    );
  }
}

class _VideoFilterSwitch extends ConsumerWidget {
  const _VideoFilterSwitch({required this.filter, required this.title});

  final VideoFilter filter;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.videoFilters.contains(filter)),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: Text(title),
        value: enabled,
        onChanged: (value) =>
            controller.toggleVideoFilter(filter, enabled: value),
      ),
    );
  }
}
