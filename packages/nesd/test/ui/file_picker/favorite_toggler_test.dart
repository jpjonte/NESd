import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/favorite_toggler.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

class _MockNesController extends Mock implements NesController {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

const _file = FilesystemFile(
  path: '/roms/game.nes',
  name: 'game.nes',
  type: FilesystemFileType.file,
);

const _rom = RomInfo(file: _file, romHash: 'abc');

void main() {
  late _MockNesController nes;
  late _MockSettingsController settings;
  late _MockToaster toaster;
  late FavoriteToggler toggler;

  setUpAll(() {
    registerFallbackValue(_file);
    registerFallbackValue(_rom);
    registerFallbackValue(Toast.info(''));
  });

  setUp(() {
    nes = _MockNesController();
    settings = _MockSettingsController();
    toaster = _MockToaster();

    toggler = FavoriteToggler(
      nesController: nes,
      settingsController: settings,
      toaster: toaster,
    );

    when(() => settings.favoriteRoms).thenReturn(const []);
  });

  test('starring hashes the file and stores it', () async {
    when(() => nes.identifyRom(_file)).thenAnswer((_) async => _rom);

    await toggler.toggle(_file);

    verify(() => settings.addFavorite(_rom)).called(1);
  });

  test('unstarring removes the favorite without reading the file', () async {
    when(() => settings.favoriteRoms).thenReturn(const [_rom]);

    await toggler.toggle(_file);

    verify(() => settings.removeFavorite(_rom)).called(1);
    verifyNever(() => nes.identifyRom(any()));
  });

  test('an unreadable file shows an error and stores nothing', () async {
    when(() => nes.identifyRom(_file)).thenThrow(RangeError('empty file'));

    await toggler.toggle(_file);

    verifyNever(() => settings.addFavorite(any()));

    final toast =
        verify(() => toaster.send(captureAny())).captured.single as Toast;

    expect(toast.type, ToastType.error);
  });

  group('an archive played since it was starred', () {
    const archive = FilesystemFile(
      path: '/roms/game.zip',
      name: 'game.zip',
      type: FilesystemFileType.file,
    );

    const played = RomInfo(
      file: FilesystemFile(
        path: '/roms/game.zip:game.nes',
        name: 'game.nes',
        type: FilesystemFileType.file,
      ),
      romHash: 'abc',
    );

    test('still shows as a favorite on its archive row', () {
      expect(isFavoritePath(const [played], archive.path), isTrue);
    });

    test('is unstarred from its archive row', () async {
      when(() => settings.favoriteRoms).thenReturn(const [played]);

      await toggler.toggle(archive);

      verify(() => settings.removeFavorite(played)).called(1);
      verifyNever(() => nes.identifyRom(any()));
    });
  });

  test('a sibling file sharing a name prefix is not a favorite', () {
    const favorite = RomInfo(
      file: FilesystemFile(
        path: '/roms/game.nes',
        name: 'game.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(isFavoritePath(const [favorite], '/roms/game'), isFalse);
  });

  test('a multi-ROM archive asks to star an entry inside', () async {
    const archive = FilesystemFile(
      path: '/roms/pack.zip',
      name: 'pack.zip',
      type: FilesystemFileType.file,
    );

    when(
      () => nes.identifyRom(archive),
    ).thenThrow(TooManyRoms('/roms/pack.zip'));

    await toggler.toggle(archive);

    verifyNever(() => settings.addFavorite(any()));

    final toast =
        verify(() => toaster.send(captureAny())).captured.single as Toast;

    expect(toast.message, contains('Open the archive'));
  });
}
