import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/features.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/mixer_sliders.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/gamepad_slots.dart';
import 'package:nesd/ui/settings/controls/reset_bindings_button.dart';
import 'package:nesd/ui/settings/controls/show_touch_controls_switch.dart';
import 'package:nesd/ui/settings/controls/touch_editor_button.dart';
import 'package:nesd/ui/settings/controls/turbo_speed_selector.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/debug/log_level_dropdown.dart';
import 'package:nesd/ui/settings/debug/view_log_button.dart';
import 'package:nesd/ui/settings/general/auto_load_switch.dart';
import 'package:nesd/ui/settings/general/auto_save_interval.dart';
import 'package:nesd/ui/settings/general/auto_save_switch.dart';
import 'package:nesd/ui/settings/general/fast_forward_speed_selector.dart';
import 'package:nesd/ui/settings/general/region_selector.dart';
import 'package:nesd/ui/settings/general/rewind_switch.dart';
import 'package:nesd/ui/settings/general/theme_mode_selector.dart';
import 'package:nesd/ui/settings/graphics/border_switch.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/graphics/overscan_sliders.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/graphics/palette_import_button.dart';
import 'package:nesd/ui/settings/graphics/palette_preview.dart';
import 'package:nesd/ui/settings/graphics/palette_remove_button.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_dropdown.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_slider.dart';
import 'package:nesd/ui/settings/graphics/renderer_selector.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/graphics/video_filter_switches.dart';
import 'package:nesd/ui/settings/settings.dart';

typedef SettingsEntryBuilder =
    Widget Function(BuildContext context, WidgetRef ref);

typedef SettingsVisibility = bool Function(WidgetRef ref);

enum SettingsCategory {
  general('General', Icons.tune),
  video('Video', Icons.tv),
  audio('Audio', Icons.volume_up),
  controls('Controls', Icons.sports_esports),
  advanced('Advanced', Icons.build);

  const SettingsCategory(this.title, this.icon);

  final String title;
  final IconData icon;
}

@immutable
class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<SettingsItem> items;
}

@immutable
sealed class SettingsItem {
  const SettingsItem();
}

@immutable
class SettingsEntry extends SettingsItem {
  const SettingsEntry({
    required this.title,
    required this.builder,
    this.visibleWhen,
  });

  final String title;
  final SettingsEntryBuilder builder;

  final SettingsVisibility? visibleWhen;
}

@immutable
class SettingsGroup extends SettingsItem {
  const SettingsGroup({
    required this.id,
    required this.title,
    required this.entries,
  });

  final String id;
  final String title;
  final List<SettingsEntry> entries;
}

List<SettingsSection> sectionsOf(SettingsCategory category) =>
    switch (category) {
      SettingsCategory.general => _general,
      SettingsCategory.video => _video,
      SettingsCategory.audio => _audio,
      SettingsCategory.controls => _controls,
      SettingsCategory.advanced => _advanced,
    };

final _general = [
  SettingsSection(
    id: 'general.saves',
    title: 'Saves',
    items: [
      SettingsEntry(
        title: 'Auto Save',
        builder: (_, _) => const AutoSaveSwitch(),
      ),
      SettingsEntry(
        title: 'Auto Save Interval',
        builder: (_, _) => const AutoSaveInterval(),
      ),
      SettingsEntry(
        title: 'Load latest save state on start',
        builder: (_, _) => const AutoLoadSwitch(),
      ),
    ],
  ),
  SettingsSection(
    id: 'general.emulation',
    title: 'Emulation',
    items: [
      SettingsEntry(
        title: 'Console Region',
        builder: (_, _) => const RegionSelector(),
      ),
      if (Features.rewind)
        SettingsEntry(
          title: 'Enable Rewind',
          builder: (_, _) => const RewindSwitch(),
        ),
      SettingsEntry(
        title: 'Fast Forward Speed',
        builder: (_, _) => const FastForwardSpeedSelector(),
      ),
    ],
  ),
  SettingsSection(
    id: 'general.appearance',
    title: 'Appearance',
    items: [
      SettingsEntry(
        title: 'Theme Mode',
        builder: (_, _) => const ThemeModeSelector(),
      ),
    ],
  ),
];

bool _generatedPaletteSelected(WidgetRef ref) =>
    ref.watch(settingsControllerProvider.select((s) => s.paletteId)) ==
    NesPaletteId.generated;

bool _crtEnabled(WidgetRef ref) => ref.watch(
  settingsControllerProvider.select(
    (s) => s.videoFilters.contains(VideoFilter.crt),
  ),
);

final _video = [
  SettingsSection(
    id: 'video.display',
    title: 'Display',
    items: [
      if (Features.gpuRenderer)
        SettingsEntry(
          title: 'Renderer',
          builder: (_, _) => const RendererSelector(),
        ),
      SettingsEntry(
        title: 'Scaling',
        builder: (_, _) => const ScalingDropdown(),
      ),
      SettingsEntry(
        title: 'Show Border',
        builder: (_, _) => const BorderSwitch(),
      ),
    ],
  ),
  SettingsSection(
    id: 'video.aspect',
    title: 'Aspect & Overscan',
    items: [
      SettingsEntry(
        title: 'Pixel Aspect Ratio',
        builder: (_, _) => const PixelAspectRatioDropdown(),
      ),
      SettingsEntry(
        title: 'Custom Pixel Aspect Ratio',
        builder: (_, ref) => PixelAspectRatioSlider(
          enabled:
              ref.watch(
                settingsControllerProvider.select((s) => s.pixelAspectRatio),
              ) ==
              PixelAspectRatio.custom,
        ),
      ),
      SettingsEntry(
        title: 'Overscan Top',
        builder: (_, _) => const OverscanTopSlider(),
      ),
      SettingsEntry(
        title: 'Overscan Bottom',
        builder: (_, _) => const OverscanBottomSlider(),
      ),
      SettingsEntry(
        title: 'Overscan Left',
        builder: (_, _) => const OverscanLeftSlider(),
      ),
      SettingsEntry(
        title: 'Overscan Right',
        builder: (_, _) => const OverscanRightSlider(),
      ),
    ],
  ),
  SettingsSection(
    id: 'video.palette',
    title: 'Palette',
    items: [
      SettingsEntry(
        title: 'Palette',
        builder: (_, _) => const PaletteDropdown(),
      ),
      SettingsEntry(
        title: 'Palette Preview',
        builder: (_, _) => const PalettePreview(),
      ),
      SettingsEntry(
        title: 'Import palette…',
        builder: (_, _) => const PaletteImportButton(),
      ),
      SettingsEntry(
        title: 'Remove palette',
        builder: (_, _) => const PaletteRemoveButton(),
        visibleWhen: (ref) =>
            PaletteRemoveButton.selectedUserPalette(ref) != null,
      ),
      SettingsEntry(
        title: 'Hue',
        builder: (_, _) => const HueSlider(),
        visibleWhen: _generatedPaletteSelected,
      ),
      SettingsEntry(
        title: 'Saturation',
        builder: (_, _) => const SaturationSlider(),
        visibleWhen: _generatedPaletteSelected,
      ),
      SettingsEntry(
        title: 'Contrast',
        builder: (_, _) => const ContrastSlider(),
        visibleWhen: _generatedPaletteSelected,
      ),
      SettingsEntry(
        title: 'Brightness',
        builder: (_, _) => const BrightnessSlider(),
        visibleWhen: _generatedPaletteSelected,
      ),
      SettingsEntry(
        title: 'Gamma',
        builder: (_, _) => const GammaSlider(),
        visibleWhen: _generatedPaletteSelected,
      ),
    ],
  ),
  if (Features.videoFilters)
    SettingsSection(
      id: 'video.filters',
      title: 'Filters',
      items: [
        SettingsEntry(
          title: 'Upscaling (xBR)',
          builder: (_, _) => const UpscalingFilterSwitch(),
        ),
        SettingsEntry(
          title: 'Smoothing',
          builder: (_, _) => const SmoothingFilterSwitch(),
        ),
        SettingsEntry(
          title: 'CRT effect',
          builder: (_, _) => const CrtFilterSwitch(),
        ),
        SettingsEntry(
          title: 'Scanline Intensity',
          builder: (_, _) => const ScanlineIntensitySlider(),
          visibleWhen: _crtEnabled,
        ),
        SettingsEntry(
          title: 'Mask Strength',
          builder: (_, _) => const MaskStrengthSlider(),
          visibleWhen: _crtEnabled,
        ),
        SettingsEntry(
          title: 'Curvature',
          builder: (_, _) => const CurvatureSlider(),
          visibleWhen: _crtEnabled,
        ),
      ],
    ),
];

final _audio = [
  SettingsSection(
    id: 'audio.output',
    title: 'Output',
    items: [
      SettingsEntry(title: 'Volume', builder: (_, _) => const VolumeSlider()),
      SettingsEntry(
        title: 'Low Pass Filter',
        builder: (_, _) => const LowPassFilterSwitch(),
      ),
      SettingsEntry(
        title: 'Swap Duty Cycles',
        builder: (_, _) => const SwapDutyCyclesSwitch(),
      ),
    ],
  ),
  SettingsSection(
    id: 'audio.mixer',
    title: 'Mixer',
    items: [
      SettingsEntry(
        title: 'Pulse 1',
        builder: (_, _) => const Pulse1GainSlider(),
      ),
      SettingsEntry(
        title: 'Pulse 2',
        builder: (_, _) => const Pulse2GainSlider(),
      ),
      SettingsEntry(
        title: 'Triangle',
        builder: (_, _) => const TriangleGainSlider(),
      ),
      SettingsEntry(title: 'Noise', builder: (_, _) => const NoiseGainSlider()),
      SettingsEntry(title: 'DMC', builder: (_, _) => const DmcGainSlider()),
      SettingsEntry(title: 'MMC5', builder: (_, _) => const Mmc5GainSlider()),
      SettingsEntry(
        title: 'Namco 163',
        builder: (_, _) => const Namco163GainSlider(),
      ),
    ],
  ),
];

const _player1Actions = [
  controller1Up,
  controller1Down,
  controller1Left,
  controller1Right,
  controller1Start,
  controller1Select,
  controller1A,
  controller1B,
  controller1TurboA,
  controller1TurboB,
];

const _player2Actions = [
  controller2Up,
  controller2Down,
  controller2Left,
  controller2Right,
  controller2Start,
  controller2Select,
  controller2A,
  controller2B,
  controller2TurboA,
  controller2TurboB,
];

SettingsGroup _bindingGroup(
  String id,
  String title,
  Iterable<InputAction> actions,
) => SettingsGroup(
  id: id,
  title: title,
  entries: [
    for (final action in actions)
      if (isBindable(action))
        SettingsEntry(
          title: action.title,
          builder: (_, _) => BindingTile(action: action),
        ),
  ],
);

final _controls = [
  SettingsSection(
    id: 'controls.options',
    title: 'Options',
    items: [
      SettingsEntry(
        title: 'Turbo Speed',
        builder: (_, _) => const TurboSpeedSelector(),
      ),
      SettingsEntry(
        title: 'Show touch controls',
        builder: (_, _) => const ShowTouchControlsSwitch(),
      ),
      SettingsEntry(
        title: 'Edit touch controls',
        builder: (_, _) => const TouchEditorButton(),
      ),
    ],
  ),
  SettingsSection(
    id: 'controls.gamepads',
    title: 'Gamepads',
    items: [
      SettingsEntry(
        title: 'Gamepads',
        builder: (_, _) => const GamepadSlotsSection(),
      ),
    ],
  ),
  SettingsSection(
    id: 'controls.bindings',
    title: 'Bindings',
    items: [
      SettingsEntry(
        title: 'Profile',
        builder: (_, _) => const ProfileSelectionHeader(),
      ),
      _bindingGroup('controls.bindings.menu', 'Menu', menuActions),
      _bindingGroup('controls.bindings.emulator', 'Emulator', emulatorActions),
      _bindingGroup('controls.bindings.player1', 'Player 1', _player1Actions),
      _bindingGroup('controls.bindings.player2', 'Player 2', _player2Actions),
      _bindingGroup(
        'controls.bindings.saveStates',
        'Save States',
        saveStateActions,
      ),
      _bindingGroup('controls.bindings.tools', 'Tools', toolActions),
      SettingsEntry(
        title: 'Reset Control Bindings',
        builder: (_, _) => const ResetBindingsButton(),
      ),
    ],
  ),
];

final _advanced = [
  SettingsSection(
    id: 'advanced.main',
    title: 'Advanced',
    items: [
      SettingsEntry(
        title: 'Show debug overlay',
        builder: (_, _) => const DebugOverlaySwitch(),
      ),
      SettingsEntry(
        title: 'Log level',
        builder: (_, _) => const LogLevelDropdown(),
      ),
      SettingsEntry(
        title: 'View log',
        builder: (_, _) => const ViewLogButton(),
      ),
    ],
  ),
];
