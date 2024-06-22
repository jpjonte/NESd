import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/settings.dart';

class SettingsScreen extends HookWidget {
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
    final tabController = useTabController(initialLength: 5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TabBar(
                controller: tabController,
                tabs: const [
                  Tab(child: Center(child: Text('General'))),
                  Tab(child: Center(child: Text('Graphics'))),
                  Tab(child: Center(child: Text('Audio'))),
                  Tab(child: Center(child: Text('Controls'))),
                  Tab(child: Center(child: Text('Debug'))),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    GeneralSettings(),
                    GraphicsSettings(),
                    AudioSettings(),
                    ControlSettings(),
                    DebugSettings(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        AutoSaveDropDown(),
      ],
    );
  }
}

class GraphicsSettings extends StatelessWidget {
  const GraphicsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        StretchSwitch(),
        BorderSwitch(),
        ScalingDropDown(),
      ],
    );
  }
}

class AudioSettings extends StatelessWidget {
  const AudioSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        VolumeSlider(),
      ],
    );
  }
}

class ControlSettings extends ConsumerWidget {
  const ControlSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyMap = ref.watch(
      settingsControllerProvider.select((s) => s.keyMap),
    );

    return ListView(
      children: [
        for (final action in allActions)
          KeyBindingTile(
            binding: keyMap.firstWhere(
              (binding) => binding.action == action,
              orElse: () => KeyBinding(keys: {}, action: action),
            ),
          ),
      ],
    );
  }
}

class KeyBindingTile extends StatelessWidget {
  const KeyBindingTile({required this.binding, super.key});

  final KeyBinding binding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(binding.action.title),
      trailing: KeyBinder(binding: binding),
    );
  }
}

class KeyBinder extends HookConsumerWidget {
  const KeyBinder({required this.binding, super.key});

  final KeyBinding binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);

    final theme = Theme.of(context);

    final keys = useState<Set<LogicalKeyboardKey>>({});

    return Focus(
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyRepeatEvent) {
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent) {
          keys.value = {
            ...keys.value,
            event.logicalKey,
          };

          return KeyEventResult.handled;
        }

        if (event is KeyUpEvent) {
          node.unfocus();

          controller.updateKeyBinding(
            KeyBinding(
              keys: keys.value,
              action: binding.action,
            ),
          );
        }

        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final hasFocus = focusNode.hasFocus;

          String keysToString(Set<LogicalKeyboardKey> keys) {
            final sorted = keys.toList()..sort((a, b) => b.keyId - a.keyId);

            return sorted.map((key) => key.keyLabel).join(' + ');
          }

          final text = hasFocus
              ? (keys.value.isNotEmpty ? keysToString(keys.value) : '...')
              : keysToString(binding.keys);

          return GestureDetector(
            onTap: () {
              if (hasFocus) {
                focusNode.unfocus();
              } else {
                keys.value = {};
                focusNode.requestFocus();
              }
            },
            onDoubleTap: () => controller.clearKeyBinding(binding.action),
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.withAlpha(hasFocus ? 255 : 100),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(child: Text(text)),
            ),
          );
        },
      ),
    );
  }
}

class DebugSettings extends StatelessWidget {
  const DebugSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        DebugTileSwitch(),
        CartridgeSwitch(),
      ],
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
