import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_link/rom_downloader.dart';
import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';
import 'package:nesd/ui/emulator/rom_link/rom_link_controller.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/menu/menu_screen.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../../robot.dart';
import 'fake_rom_fetcher.dart';

final _nestest = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

final _romUrl = Uri.parse('https://example.com/roms/nestest.nes');

Uri _page([String extra = '']) => Uri.parse(
  'https://nesd.jpj.dev/play/'
  '?rom=${Uri.encodeQueryComponent(_romUrl.toString())}$extra',
);

class _Harness {
  _Harness(this.r, this.storage, this.fetcher);

  final Robot r;
  final MemoryStorageFilesystem storage;
  final FakeRomFetcher fetcher;

  List<String> get toasts => [
    for (final toast in r.container.read(toastStateProvider)) toast.message,
  ];

  List<String> get recentPaths => [
    for (final rom in r.container.read(settingsControllerProvider).recentRoms)
      rom.file.path,
  ];

  Future<void> waitForGame() => r.waitUntil(
    () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
  );

  Future<void> quitGame() async {
    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  }
}

Future<_Harness> _start(
  WidgetTester tester, {
  Uri? page,
  FakeRomFetcher? fetcher,
}) async {
  final r = Robot(tester);
  final storage = MemoryStorageFilesystem();
  final romFetcher = fetcher ?? FakeRomFetcher.bytes(_nestest);

  await r.pumpApp(
    storage: storage,
    overrides: [
      romFetcherProvider.overrideWithValue(romFetcher),
      if (page != null)
        initialRomProvider.overrideWith(
          () => InitialRom(initialValue: InitialRomLink(page)),
        ),
    ],
    settle: false,
  );

  return _Harness(r, storage, romFetcher);
}

void main() {
  testWidgets('a ROM link starts the game without storing it', (tester) async {
    final h = await _start(tester, page: _page());

    await h.waitForGame();

    expect(h.fetcher.requests, [_romUrl]);
    expect(await h.storage.list(webRomsDirectory), isEmpty);
    expect(h.recentPaths, isEmpty);
    expect(h.r.container.read(initialRomProvider), isNull);

    await h.r.emulator.tapMenu();

    expect(find.byKey(MenuScreen.saveRomKey), findsOneWidget);

    await h.r.menuScreen.tapResume();
    await h.quitGame();

    expect(h.r.container.read(romLinkControllerProvider), isNull);
  });

  testWidgets('saving a linked ROM stores it and adds it to the recents', (
    tester,
  ) async {
    final h = await _start(tester, page: _page());

    await h.waitForGame();
    await h.r.emulator.tapMenu();
    await h.r.menuScreen.tapSaveRom();
    await h.r.waitUntil(
      () => h.r.container.read(romLinkControllerProvider) == null,
    );

    const stored = '$webRomsDirectory/nestest.nes';

    expect(
      await h.r.tester.runAsync(() => h.storage.read(stored)),
      Uint8List.fromList(_nestest),
    );
    expect(h.recentPaths, [stored]);
    expect(h.toasts, contains('Saved nestest.nes to browser storage'));
    expect(find.byKey(MenuScreen.saveRomKey), findsNothing);

    await h.r.menuScreen.tapQuitGame();
    await h.r.waitUntil(() => h.r.container.read(nesStateProvider) == null);
  });

  testWidgets('a failed download stays on the main menu with a toast', (
    tester,
  ) async {
    final h = await _start(
      tester,
      page: _page(),
      fetcher: FakeRomFetcher(
        (_) async => RomResponse(status: 404, bytes: () async => Uint8List(0)),
      ),
    );

    await h.r.waitUntil(
      () => h.toasts.any((message) => message.contains('404')),
    );

    expect(
      h.toasts,
      contains(startsWith('Failed to load ROM: Could not download')),
    );
    expect(h.r.container.read(nesStateProvider), isNull);
    expect(h.r.container.read(currentRouteProvider), MainRoute.name);
    expect(h.r.container.read(romLinkControllerProvider), isNull);
  });

  testWidgets('an invalid link reports why without fetching', (tester) async {
    final h = await _start(
      tester,
      page: Uri.parse('https://nesd.jpj.dev/play/?rom=file:///game.nes'),
    );

    await h.r.waitUntil(() => h.toasts.isNotEmpty);

    expect(h.toasts, [
      'Failed to load ROM: Unsupported ROM URL: file:///game.nes',
    ]);
    expect(h.fetcher.requests, isEmpty);
  });

  testWidgets('a slot loads that save state instead of the latest', (
    tester,
  ) async {
    final h = await _start(tester);
    final links = h.r.container.read(romLinkControllerProvider.notifier);
    final controller = h.r.container.read(nesControllerProvider);

    await h.r.tester.runAsync(() => links.open(_page()));
    await h.waitForGame();
    await h.r.tester.runAsync(() => controller.saveState(4));
    await h.quitGame();

    h.r.container.read(toastStateProvider.notifier).clear();

    await h.r.tester.runAsync(() => links.open(_page('&slot=4')));
    await h.waitForGame();
    await h.r.waitUntil(() => h.toasts.contains('State loaded from slot 4'));

    expect(h.toasts, isNot(contains('Loaded latest save state')));

    await h.quitGame();
  });

  testWidgets('an invalid slot is ignored with a warning', (tester) async {
    final h = await _start(tester, page: _page('&slot=12'));

    await h.waitForGame();

    expect(
      h.toasts,
      contains("Ignoring save state slot '12': expected a number from 0 to 9"),
    );

    await h.quitGame();
  });
}
