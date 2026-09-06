import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/common/settings_section_header.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_group_tile.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFilesystem extends Mock implements Filesystem {}

void main() {
  Future<ProviderContainer> pumpContent(
    WidgetTester tester,
    SettingsCategory category,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageFilesystemProvider.overrideWithValue(
            MemoryStorageFilesystem(),
          ),
          filesystemProvider.overrideWithValue(_FakeFilesystem()),
        ],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SettingsCategoryContent(
                category: category,
                sectionKeys: createSectionKeys(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(
      tester.element(find.byType(SettingsCategoryContent)),
    );
  }

  testWidgets('a multi-section category shows one header per section', (
    tester,
  ) async {
    await pumpContent(tester, SettingsCategory.video);

    expect(find.byType(SettingsSectionHeader), findsNWidgets(4));
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Aspect & Overscan'), findsOneWidget);
    expect(find.text('Palette'), findsNWidgets(2)); // header + dropdown tile
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('a single-section category shows no header', (tester) async {
    await pumpContent(tester, SettingsCategory.advanced);

    expect(find.byType(SettingsSectionHeader), findsNothing);
    expect(find.byType(DebugOverlaySwitch), findsOneWidget);
  });

  testWidgets('entries with visibleWhen follow the setting', (tester) async {
    final container = await pumpContent(tester, SettingsCategory.video);

    expect(find.byType(HueSlider), findsNothing);

    container.read(settingsControllerProvider.notifier).paletteId =
        NesPaletteId.generated;
    await tester.pumpAndSettle();

    expect(find.byType(HueSlider), findsOneWidget);
  });

  testWidgets('the CRT sliders follow the CRT filter', (tester) async {
    final container = await pumpContent(tester, SettingsCategory.video);

    expect(find.byType(ScanlineIntensitySlider), findsNothing);

    container
        .read(settingsControllerProvider.notifier)
        .toggleVideoFilter(VideoFilter.crt, enabled: true);
    await tester.pumpAndSettle();

    expect(find.byType(ScanlineIntensitySlider), findsOneWidget);
  });

  testWidgets('binding groups start collapsed and expand on tap', (
    tester,
  ) async {
    await pumpContent(tester, SettingsCategory.controls);

    expect(find.byType(BindingTile), findsNothing);
    expect(find.text('Player 1 (10)'), findsOneWidget);

    final header = find.byKey(
      SettingsGroupTile.headerKey('controls.bindings.player1'),
    );

    await tester.ensureVisible(header);
    await tester.tap(header);
    await tester.pumpAndSettle();

    expect(find.byType(BindingTile), findsNWidgets(10));

    await tester.tap(header);
    await tester.pumpAndSettle();

    expect(find.byType(BindingTile), findsNothing);
  });

  testWidgets('createSectionKeys covers every section exactly once', (
    tester,
  ) async {
    final keys = createSectionKeys();

    final ids = [
      for (final category in SettingsCategory.values)
        for (final section in sectionsOf(category)) section.id,
    ];

    expect(keys.keys.toSet(), ids.toSet());
    expect(keys.length, ids.length);
  });
}
