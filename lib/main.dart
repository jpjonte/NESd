import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/android_saf_file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/native_file_system.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sharedPreferencesOptions = SharedPreferencesOptions();

  final preferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  final applicationSupport = await getApplicationSupportDirectory();

  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: preferences,
    sharedPreferencesAsyncOptions: sharedPreferencesOptions,
    migrationCompletedKey: 'migrationCompleted',
  );

  final fileSystem =
      Platform.isAndroid ? AndroidSafFileSystem() : NativeFileSystem();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        packageInfoProvider.overrideWithValue(packageInfo),
        fileSystemProvider.overrideWithValue(fileSystem),
        applicationSupportPathProvider.overrideWithValue(
          applicationSupport.path,
        ),
      ],
      child: const NesdApp(),
    ),
  );
}
