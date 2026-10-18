import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:nesd/features.dart';
import 'package:nesd/ui/settings/settings.dart';

const settingsBackupVersion = 1;

const deviceSpecificSettingsKeys = {
  'recentRoms',
  'recentRomPaths',
  'favoriteRoms',
  'lastRomPath',
};

const _unsupportedSettingsKeys = {
  if (!Features.gpuRenderer) 'renderer',
  if (!Features.rewind) 'rewind',
};

final _stamp = DateFormat('yyyyMMdd-HHmmss');

String settingsBackupFileName(DateTime now) =>
    'nesd-settings-${_stamp.format(now)}.json';

String encodeSettingsBackup(Settings settings, {required DateTime now}) =>
    const JsonEncoder.withIndent('  ').convert({
      'version': settingsBackupVersion,
      'exportedAt': now.toIso8601String(),
      'settings': settings.toJson()
        ..removeWhere((key, _) => deviceSpecificSettingsKeys.contains(key)),
    });

Map<String, dynamic> decodeSettingsBackup(String source) {
  final Object? json;

  try {
    json = jsonDecode(source);
  } on FormatException {
    throw const FormatException('not a NESd settings file');
  }

  if (json case {
    'version': final int version,
    'settings': final Map<String, dynamic> settings,
  }) {
    if (version > settingsBackupVersion) {
      throw const FormatException('made by a newer version of NESd');
    }

    return settings..removeWhere(
      (key, _) =>
          deviceSpecificSettingsKeys.contains(key) ||
          _unsupportedSettingsKeys.contains(key),
    );
  }

  throw const FormatException('not a NESd settings file');
}
