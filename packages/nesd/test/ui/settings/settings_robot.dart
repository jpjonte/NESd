import 'dart:io';

import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/graphics/palette_import_button.dart';
import 'package:nesd/ui/settings/settings_screen.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../base_robot.dart';
import 'controls/controls_settings_robot.dart';
import 'debug/debug_settings_robot.dart';

class SettingsScreenRobot extends BaseRobot {
  SettingsScreenRobot(super.tester)
    : debug = DebugSettingsRobot(tester),
      controls = ControlsSettingsRobot(tester);

  final ControlsSettingsRobot controls;
  final DebugSettingsRobot debug;

  Future<void> pumpSettingsScreen({List<Override> overrides = const []}) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await _loadFont('Inter', ['assets/fonts/Inter-Regular.ttf']);
    await _loadFont('MaterialIcons', [
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageFilesystemProvider.overrideWithValue(
            MemoryStorageFilesystem(),
          ),
          ...overrides,
        ],
        child: MaterialApp(theme: nesdThemeLight, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

  void expectSettingsScreenFound() {
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  void expectTabHeadersFound() {
    expect(find.byKey(SettingsScreen.generalKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.graphicsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.audioKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.controlsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.debugKey), findsOneWidget);
  }

  void expectGeneralTabFound() {
    expect(find.byKey(SettingsScreen.generalKey), findsOneWidget);
  }

  void expectGraphicsTabFound() {
    expect(find.byKey(SettingsScreen.graphicsKey), findsOneWidget);
  }

  void expectAudioTabFound() {
    expect(find.byKey(SettingsScreen.audioKey), findsOneWidget);
  }

  void expectControlsTabFound() {
    expect(find.byKey(SettingsScreen.controlsKey), findsOneWidget);
  }

  void expectAboutDialogFound() {
    expectOne(find.byType(AboutDialog));
  }

  Future<void> tapAboutButton() async {
    await go(find.text('About NESd'));
  }

  Future<void> tapGraphicsTab() async {
    await go(find.byKey(SettingsScreen.graphicsKey));
  }

  Future<void> tapAudioTab() async {
    await go(find.byKey(SettingsScreen.audioKey));
  }

  Future<void> tapControlsTab() async {
    await go(find.byKey(SettingsScreen.controlsKey));
  }

  Future<void> tapDebugTab() async {
    await go(find.byKey(SettingsScreen.debugKey));
  }

  Future<void> selectPalette(NesPaletteId id) async {
    await go(find.byType(DropdownButton<PaletteSelection>));
    await go(find.text(id.displayName).last);
  }

  Future<void> selectUserPalette(String name) async {
    await go(find.byType(DropdownButton<PaletteSelection>));
    await go(find.text(name).last);
  }

  Future<void> tapImportPalette() async {
    final finder = find.byType(PaletteImportButton);

    await tester.ensureVisible(finder);
    await go(finder);
  }

  Future<void> tapRemovePalette() async {
    final finder = find.text('Remove palette');

    await tester.ensureVisible(finder);
    await go(finder);
  }

  Future<void> _loadFont(String family, List<String> fontFiles) async {
    final fontLoader = FontLoader(family);

    for (final fontFile in fontFiles) {
      final fontData = rootBundle.load(fontFile);

      fontLoader.addFont(fontData);
    }

    await fontLoader.load();
  }
}
