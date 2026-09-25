import 'package:flutter/foundation.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_link/rom_downloader.dart';
import 'package:nesd/ui/emulator/rom_link/rom_link.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_link_controller.g.dart';

@immutable
class UnsavedRom {
  const UnsavedRom({required this.file, required this.bytes});

  final FilesystemFile file;
  final Uint8List bytes;
}

@Riverpod(keepAlive: true)
class RomLinkController extends _$RomLinkController {
  @override
  UnsavedRom? build() {
    ref.listen(nesStateProvider, (_, nes) {
      if (state case final unsaved? when nes?.romInfo.file != unsaved.file) {
        state = null;
      }
    });

    return null;
  }

  Future<bool> open(Uri page) async {
    final toaster = ref.read(toasterProvider);

    final RomLink link;
    final DownloadedRom rom;

    try {
      link = RomLink.fromPage(page);

      toaster.send(Toast.info('Downloading ${link.url}'));

      rom = await ref.read(romDownloaderProvider).download(link.url);
    } on Exception catch (e) {
      log.rom.error(
        'Failed to download ROM',
        context: {'page': page.toString()},
        error: e,
      );

      toaster.send(Toast.error('Failed to load ROM: $e'));

      return false;
    }

    if (link.invalidSlot case final slot?) {
      toaster.send(
        Toast.warning(
          "Ignoring save state slot '$slot': expected a number from 0 to 9",
        ),
      );
    }

    final file = FilesystemFile(
      path: link.url.toString(),
      name: rom.name,
      type: FilesystemFileType.file,
    );

    final nesController = ref.read(nesControllerProvider);

    final started = await nesController.startRom(
      file,
      data: rom.bytes,
      autoLoadState: link.slot == null,
      addToRecents: false,
    );

    if (!started) {
      return false;
    }

    state = UnsavedRom(file: file, bytes: rom.bytes);

    if (link.slot case final slot?) {
      await nesController.loadState(slot);
    }

    return true;
  }

  Future<void> saveToBrowser() async {
    final unsaved = state;
    final romInfo = ref.read(nesStateProvider)?.romInfo;

    if (unsaved == null || romInfo == null) {
      return;
    }

    final toaster = ref.read(toasterProvider);
    final name = unsaved.file.name;

    final file = FilesystemFile(
      path: '$webRomsDirectory/$name',
      name: name,
      type: FilesystemFileType.file,
    );

    try {
      await ref.read(storageFilesystemProvider).write(file.path, unsaved.bytes);
    } on Exception catch (e) {
      log.rom.error(
        'Failed to save ROM',
        context: {'path': file.path},
        error: e,
      );

      toaster.send(Toast.error('Failed to save ROM: $e'));

      return;
    }

    ref
        .read(settingsControllerProvider.notifier)
        .addRecentRom(
          RomInfo(
            file: file,
            hash: romInfo.hash,
            romHash: romInfo.romHash,
            chrHash: romInfo.chrHash,
            prgHash: romInfo.prgHash,
          ),
        );

    state = null;

    toaster.send(Toast.info('Saved $name to browser storage'));
  }
}
