import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  static Future<Object?> open(BuildContext context) async {
    var alreadyOpen = false;

    Navigator.popUntil(context, (route) {
      if (route.settings.name == SettingsScreen.route) {
        alreadyOpen = true;
      }

      return true;
    });

    if (!alreadyOpen) {
      return Navigator.of(context).pushNamed(route);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: const [
              Section(title: 'General'),
              AutoSaveDropDown(),
              Section(title: 'Graphics'),
              StretchSwitch(),
              BorderSwitch(),
              ScalingDropDown(),
              Section(title: 'Audio'),
              VolumeSlider(),
              Section(title: 'Debug'),
              DebugTileSwitch(),
              CartridgeSwitch(),
            ],
          ),
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
      ),
    );
  }
}

class AutoSaveDropDown extends ConsumerWidget {
  const AutoSaveDropDown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.autoSaveInterval));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Auto Save Interval'),
      subtitle: const Text('0 = off'),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        child: TextField(
          textAlign: TextAlign.end,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'off',
          ),
          controller: TextEditingController(text: setting?.toString()),
          onChanged: (value) {
            final interval = int.tryParse(value);

            controller.autoSaveInterval = interval == 0 ? null : interval;
          },
        ),
      ),
    );
  }
}

class StretchSwitch extends ConsumerWidget {
  const StretchSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.stretch));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Stretch screen'),
      value: setting,
      onChanged: (value) => controller.stretch = value,
    );
  }
}

class BorderSwitch extends ConsumerWidget {
  const BorderSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.showBorder));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Show Border'),
      value: setting,
      onChanged: (value) => controller.showBorder = value,
    );
  }
}

class ScalingDropDown extends ConsumerWidget {
  const ScalingDropDown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.scaling));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Scaling'),
      trailing: Container(
        padding: const EdgeInsets.all(4.0),
        constraints: const BoxConstraints(maxWidth: 300),
        child: DropdownMenu<Scaling>(
          initialSelection: setting,
          onSelected: (value) =>
              controller.scaling = value ?? Scaling.autoInteger,
          enableSearch: false,
          dropdownMenuEntries: const [
            DropdownMenuEntry(
              value: Scaling.autoInteger,
              label: 'Auto (integer)',
            ),
            DropdownMenuEntry(
              value: Scaling.autoSmooth,
              label: 'Auto (smooth)',
            ),
            DropdownMenuEntry(
              value: Scaling.x1,
              label: '1x',
            ),
            DropdownMenuEntry(
              value: Scaling.x2,
              label: '2x',
            ),
            DropdownMenuEntry(
              value: Scaling.x3,
              label: '3x',
            ),
            DropdownMenuEntry(
              value: Scaling.x4,
              label: '4x',
            ),
          ],
        ),
      ),
    );
  }
}

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.volume));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Volume'),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Slider(
          value: setting,
          onChanged: (value) => controller.volume = value,
          label: 'Volume',
        ),
      ),
    );
  }
}

class DebugTileSwitch extends ConsumerWidget {
  const DebugTileSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.showTiles));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Show Tiles'),
      value: setting,
      onChanged: (value) => controller.showTiles = value,
    );
  }
}

class CartridgeSwitch extends ConsumerWidget {
  const CartridgeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref
        .watch(settingsControllerProvider.select((s) => s.showCartridgeInfo));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Show Cartridge Information'),
      value: setting,
      onChanged: (value) => controller.showCartridgeInfo = value,
    );
  }
}
