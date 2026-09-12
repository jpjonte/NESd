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

  test('the entry index lists every entry once with unique ids', () {
    var expected = 0;

    for (final section in allSections) {
      for (final item in section.items) {
        expected += switch (item) {
          SettingsEntry() => 1,
          SettingsGroup(:final entries) => entries.length,
        };
      }
    }

    final ids = settingsEntryLocations.map((l) => l.id).toList();

    expect(settingsEntryLocations.length, expected);
    expect(ids.toSet().length, ids.length, reason: 'duplicate entry ids');
  });

  test('a binding location knows its group', () {
    final start = settingsEntryLocations.singleWhere(
      (l) => l.entry.title == 'Controller 2 Start',
    );

    expect(start.category, SettingsCategory.controls);
    expect(start.section.id, 'controls.bindings');
    expect(start.group?.id, 'controls.bindings.player2');
    expect(start.id, 'controls.bindings.player2/Controller 2 Start');
    expect(start.breadcrumb, 'Controls › Bindings › Player 2');
    expect(start.searchText, 'Controller 2 Start Player 2');
  });

  test('an ungrouped location has a two-level breadcrumb', () {
    final autoSave = settingsEntryLocations.singleWhere(
      (l) => l.entry.title == 'Auto Save',
    );

    expect(autoSave.group, isNull);
    expect(autoSave.id, 'general.saves/Auto Save');
    expect(autoSave.breadcrumb, 'General › Saves');
    expect(
      autoSave.searchText,
      'Auto Save Save to slot 0 on a timer and when quitting',
    );
  });
}
