import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_save_action.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/misc.dart';

import '../../../../helpers/pal_file.dart';
import '../../../robot.dart';

Future<Robot> _openEditor(
  WidgetTester tester, {
  List<Override> overrides = const [],
  StorageFilesystem? storage,
}) async {
  final robot = Robot(tester);

  await robot.pumpApp(overrides: overrides, storage: storage);

  robot.container.read(routerProvider).navigate(const SettingsRoute());
  await tester.pumpAndSettle();

  await robot.settingsScreen.openCategory(SettingsCategory.video);
  await robot.settingsScreen.tapEditPalette();

  return robot;
}

class _SlowUserPalettes extends UserPalettes {
  _SlowUserPalettes(this.saving);

  final Completer<void> saving;

  @override
  Future<void> save(String name, List<int> rgb) async {
    await saving.future;

    return super.save(name, rgb);
  }
}

void main() {
  test('names are validated', () {
    expect(paletteNameError('Mine'), isNull);
    expect(paletteNameError('   '), isNotNull);
    expect(paletteNameError('a/b'), isNotNull);
  });

  testWidgets('saving stores the palette and selects it', (tester) async {
    final robot = await _openEditor(tester);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await robot.waitUntil(
      () =>
          robot.container
              .read(userPalettesProvider)
              .value
              ?.containsKey('Default copy') ??
          false,
    );

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(const UserPaletteSelection('Default copy')),
    );
    expect(
      robot.container.read(userPalettesProvider).value!['Default copy']![0],
      equals(packPaletteColor(0x10, 0x20, 0x30)),
    );
    expect(robot.container.read(paletteEditorProvider)!.dirty, isFalse);
  });

  testWidgets('saving over another palette asks first', (tester) async {
    final robot = await _openEditor(tester);

    await robot.container
        .read(userPalettesProvider.notifier)
        .save('Taken', List.filled(64, 0x000000));

    robot.container.read(paletteEditorProvider.notifier).setName('taken');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsOneWidget);
  });

  testWidgets('declining the confirmation leaves the draft dirty', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    await robot.container
        .read(userPalettesProvider.notifier)
        .save('Taken', List.filled(64, 0x000000));

    robot.container.read(paletteEditorProvider.notifier).setName('taken');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsNothing);
    expect(
      robot.container.read(userPalettesProvider).value!.containsKey('taken'),
      isFalse,
    );
    expect(
      robot.container.read(userPalettesProvider).value!['Taken']![0],
      equals(packPaletteColor(0, 0, 0)),
    );
    expect(robot.container.read(paletteEditorProvider)!.dirty, isTrue);
  });

  testWidgets('re-saving under the same trimmed name does not prompt', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container
        .read(paletteEditorProvider.notifier)
        .setName(' Default copy ');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await robot.waitUntil(
      () =>
          robot.container
              .read(userPalettesProvider)
              .value
              ?.containsKey('Default copy') ??
          false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsNothing);

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsNothing);
    expect(
      robot.container
          .read(userPalettesProvider)
          .value!
          .keys
          .where((name) => name.toLowerCase() == 'default copy'),
      hasLength(1),
    );
  });

  testWidgets('renaming onto a stray case-variant key still prompts', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    await robot.container
        .read(userPalettesProvider.notifier)
        .save('Foo', List.filled(64, 0x000000));
    await robot.container
        .read(userPalettesProvider.notifier)
        .save('foo', List.filled(64, 0x111111));

    robot.container
        .read(paletteEditorProvider.notifier)
        .open(
          name: 'Foo',
          colors: List.filled(64, 0),
          sourceHadEmphasis: false,
        );

    robot.container.read(paletteEditorProvider.notifier).setName('foo');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsOneWidget);
  });

  testWidgets('an edit made while saving is in flight stays dirty', (
    tester,
  ) async {
    final saving = Completer<void>();

    final robot = await _openEditor(
      tester,
      overrides: [
        userPalettesProvider.overrideWith(() => _SlowUserPalettes(saving)),
      ],
    );

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x405060);

    saving.complete();
    await robot.waitUntil(
      () =>
          robot.container
              .read(userPalettesProvider)
              .value
              ?.containsKey('Default copy') ??
          false,
    );

    expect(robot.container.read(paletteEditorProvider)!.dirty, isTrue);

    final bytes = await robot.container
        .read(userPaletteStoreProvider)
        .read('Default copy');

    expect(parsePalFile(bytes!)[0], equals(packPaletteColor(0x10, 0x20, 0x30)));
  });

  testWidgets(
    'confirming an overwrite onto a stray case-variant key keeps one',
    (tester) async {
      final storage = MemoryStorageFilesystem();
      final robot = await _openEditor(tester, storage: storage);

      final dir = p.join(
        robot.container.read(applicationSupportPathProvider),
        userPalettesDirectory,
      );

      await storage.write(p.join(dir, 'Foo.pal'), greyPalFile(0x10));
      await storage.write(p.join(dir, 'foo.pal'), greyPalFile(0x20));

      robot.container.invalidate(userPalettesProvider);
      await robot.container.read(userPalettesProvider.future);

      robot.container
          .read(paletteEditorProvider.notifier)
          .open(
            name: 'Foo',
            colors: List.filled(64, 0),
            sourceHadEmphasis: false,
          );

      robot.container.read(paletteEditorProvider.notifier).setName('FOO');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);

      await tester.tap(find.text('Overwrite'));
      await robot.waitUntil(() {
        final value = robot.container.read(userPalettesProvider).value;

        return value != null &&
            value.keys.where((key) => key.toLowerCase() == 'foo').length == 1;
      });

      final loaded = robot.container.read(userPalettesProvider).value!;
      final surviving = loaded.keys.where((key) => key.toLowerCase() == 'foo');

      expect(surviving, equals(['foo']));
      expect(loaded['foo']![0], equals(packPaletteColor(0, 0, 0)));
      expect(
        robot.container.read(settingsControllerProvider).paletteSelection,
        equals(const UserPaletteSelection('foo')),
      );
    },
  );

  testWidgets(
    'saving again after an overwrite confirmation does not re-prompt',
    (tester) async {
      final storage = MemoryStorageFilesystem();
      final robot = await _openEditor(tester, storage: storage);

      final dir = p.join(
        robot.container.read(applicationSupportPathProvider),
        userPalettesDirectory,
      );

      await storage.write(p.join(dir, 'Foo.pal'), greyPalFile(0x10));
      await storage.write(p.join(dir, 'foo.pal'), greyPalFile(0x20));

      robot.container.invalidate(userPalettesProvider);
      await robot.container.read(userPalettesProvider.future);

      robot.container
          .read(paletteEditorProvider.notifier)
          .open(
            name: 'Foo',
            colors: List.filled(64, 0),
            sourceHadEmphasis: false,
          );

      robot.container.read(paletteEditorProvider.notifier).setName('FOO');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);

      await tester.tap(find.text('Overwrite'));
      await robot.waitUntil(() {
        final value = robot.container.read(userPalettesProvider).value;

        return value != null &&
            value.keys.where((key) => key.toLowerCase() == 'foo').length == 1;
      });

      robot.container
          .read(paletteEditorProvider.notifier)
          .setColor(0, 0x102030);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsNothing);

      final loaded = robot.container.read(userPalettesProvider).value!;
      final surviving = loaded.keys.where((key) => key.toLowerCase() == 'foo');

      expect(surviving, equals(['FOO']));
      expect(loaded['FOO']![0], equals(packPaletteColor(0x10, 0x20, 0x30)));
      expect(
        robot.container.read(settingsControllerProvider).paletteSelection,
        equals(const UserPaletteSelection('FOO')),
      );
    },
  );
}
