import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/features.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/debug/log_level_dropdown.dart';
import 'package:nesd/ui/settings/general/auto_save_interval.dart';
import 'package:nesd/ui/settings/general/auto_save_switch.dart';
import 'package:nesd/ui/settings/general/rewind_switch.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

void main() {
  final allSections = [
    for (final category in SettingsCategory.values) ...sectionsOf(category),
  ];

  test('every category has at least one section', () {
    for (final category in SettingsCategory.values) {
      expect(sectionsOf(category), isNotEmpty, reason: category.name);
    }
  });

  test('section ids are unique and prefixed with their category', () {
    final ids = <String>[];

    for (final category in SettingsCategory.values) {
      for (final section in sectionsOf(category)) {
        expect(section.id, startsWith('${category.name}.'));

        ids.add(section.id);
      }
    }

    expect(ids.toSet().length, ids.length);
  });

  test('group ids are unique', () {
    final ids = [
      for (final section in allSections)
        for (final item in section.items)
          if (item is SettingsGroup) item.id,
    ];

    expect(ids, isNotEmpty);
    expect(ids.toSet().length, ids.length);
  });

  test('every entry has a non-empty title', () {
    for (final section in allSections) {
      expect(section.title, isNotEmpty);

      for (final item in section.items) {
        switch (item) {
          case SettingsEntry(:final title):
            expect(title, isNotEmpty, reason: section.id);
          case SettingsGroup(:final entries):
            for (final entry in entries) {
              expect(entry.title, isNotEmpty, reason: item.id);
            }
        }
      }
    }
  });

  test('the bindings section lists every bindable action once, in order', () {
    final bindings = sectionsOf(
      SettingsCategory.controls,
    ).singleWhere((s) => s.id == 'controls.bindings');

    final titles = [
      for (final item in bindings.items)
        if (item is SettingsGroup)
          for (final entry in item.entries) entry.title,
    ];

    final expected = [
      for (final action in allActions)
        if (isBindable(action)) action.title,
    ];

    expect(titles, expected);
  });

  test('the palette section orders import before remove', () {
    final palette = sectionsOf(
      SettingsCategory.video,
    ).singleWhere((s) => s.id == 'video.palette');

    final titles = [
      for (final item in palette.items)
        if (item is SettingsEntry) item.title,
    ];

    expect(titles, [
      'Palette',
      'Palette Preview',
      'Import palette…',
      'Edit palette…',
      'Remove palette',
      'Hue',
      'Saturation',
      'Contrast',
      'Brightness',
      'Gamma',
    ]);
  });

  test('entries whose tile shows a subtitle declare it', () {
    SettingsEntry entry(SettingsCategory category, String title) => [
      for (final section in sectionsOf(category))
        for (final item in section.items)
          if (item is SettingsEntry) item,
    ].singleWhere((e) => e.title == title);

    expect(
      entry(SettingsCategory.general, 'Auto Save').subtitle,
      AutoSaveSwitch.subtitle,
    );
    expect(
      entry(SettingsCategory.general, 'Auto Save Interval').subtitle,
      AutoSaveInterval.subtitle,
    );

    if (Features.rewind) {
      expect(
        entry(SettingsCategory.general, 'Enable Rewind').subtitle,
        RewindSwitch.subtitle,
      );
    }

    expect(
      entry(SettingsCategory.audio, 'Low Pass Filter').subtitle,
      LowPassFilterSwitch.subtitle,
    );
    expect(
      entry(SettingsCategory.audio, 'Swap Duty Cycles').subtitle,
      SwapDutyCyclesSwitch.subtitle,
    );
    expect(
      entry(SettingsCategory.advanced, 'Log level').subtitle,
      LogLevelDropdown.subtitle,
    );
  });
}
