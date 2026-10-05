import 'package:collection/collection.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_toggler.g.dart';

bool isFavoritePath(List<RomInfo> favorites, String path) =>
    _favoriteAt(favorites, path) != null;

RomInfo? _favoriteAt(List<RomInfo> favorites, String path) =>
    favorites.firstWhereOrNull((favorite) {
      final favoritePath = favorite.file.path;

      return favoritePath == path ||
          splitArchivePath(favoritePath)?.archivePath == path;
    });

@riverpod
FavoriteToggler favoriteToggler(Ref ref) => FavoriteToggler(
  nesController: ref.watch(nesControllerProvider),
  settingsController: ref.watch(settingsControllerProvider.notifier),
  toaster: ref.watch(toasterProvider),
);

class FavoriteToggler {
  FavoriteToggler({
    required this.nesController,
    required this.settingsController,
    required this.toaster,
  });

  final NesController nesController;
  final SettingsController settingsController;
  final Toaster toaster;

  Future<void> toggle(FilesystemFile file) async {
    final existing = _favoriteAt(settingsController.favoriteRoms, file.path);

    if (existing != null) {
      settingsController.removeFavorite(existing);

      return;
    }

    final RomInfo rom;

    try {
      rom = await nesController.identifyRom(file);
    } on TooManyRoms {
      toaster.send(Toast.info('Open the archive to star a game inside it'));

      return;
    } on Object catch (e) {
      log.rom.warning(
        'Could not read ROM to star it',
        context: {'path': file.path},
        error: e,
      );

      toaster.send(Toast.error('Could not read ${file.name}'));

      return;
    }

    settingsController.addFavorite(rom);
  }
}
