import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsBackupActions {
  const SettingsBackupActions();

  Future<Uri?> exportBackup(String contents, {required String fileName}) =>
      FilePicker.saveFile(
        bytes: utf8.encode(contents),
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

  Future<PlatformFile?> pickBackup() =>
      FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
}

final settingsBackupActionsProvider = Provider<SettingsBackupActions>(
  (ref) => const SettingsBackupActions(),
);
