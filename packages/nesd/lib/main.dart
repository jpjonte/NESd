import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/bench/bench_runner.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_setup.dart';
import 'package:nesd/profile/dev_profile_migration.dart';
import 'package:nesd/soak/soak_config.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/android_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/native_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_factory.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_filesystem.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/soak/soak_runner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  installUiLog();
  installErrorHooks();

  SoakConfig? soakConfig;

  if (!kIsWeb) {
    // Headless benchmark mode
    final benchResult = await maybeRunBench();

    if (benchResult != null) {
      log.telemetry.emit(benchResult.logLine);

      exit(0);
    }

    // Unattended audio soak mode
    soakConfig = await maybeReadSoakConfig();
  }

  _addLicenses();

  const sharedPreferencesOptions = SharedPreferencesOptions();

  final applicationSupportPath = kIsWeb
      ? webStorageRoot
      : (await getApplicationSupportDirectory()).path;

  if (!kIsWeb) {
    await _migrateLinuxDevProfile(Directory(applicationSupportPath));
  }

  final preferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  if (!kIsWeb) {
    attachLogFile(NesdLog.instance, applicationSupportPath);
  }

  logAppStart(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
    platform: kIsWeb ? 'web' : Platform.operatingSystem,
    flavor: appFlavor,
  );

  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: preferences,
    sharedPreferencesAsyncOptions: sharedPreferencesOptions,
    migrationCompletedKey: 'migrationCompleted',
  );

  StorageFilesystem storage;
  String? startupWarning;

  try {
    storage = await createStorageFilesystem();
  } on Exception catch (e, s) {
    log.app.error(
      'Persistent storage is unavailable; using in-memory storage',
      error: e,
      stackTrace: s,
    );

    storage = MemoryStorageFilesystem();
    startupWarning =
        'Persistent storage is unavailable. '
        'Imported games and saves will be lost when NESd closes.';
  }

  final Filesystem filesystem;

  if (kIsWeb) {
    filesystem = WebFilesystem(storage: storage);
  } else {
    filesystem = Platform.isAndroid ? AndroidFilesystem() : NativeFilesystem();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        packageInfoProvider.overrideWithValue(packageInfo),
        filesystemProvider.overrideWithValue(filesystem),
        storageFilesystemProvider.overrideWithValue(storage),
        applicationSupportPathProvider.overrideWithValue(
          applicationSupportPath,
        ),
        initialRomProvider.overrideWith(
          () => InitialRom(
            initialValue: arguments.isNotEmpty ? arguments.first : null,
          ),
        ),
        if (startupWarning != null)
          startupWarningProvider.overrideWithValue(startupWarning),
        if (soakConfig != null)
          soakConfigProvider.overrideWith((ref) => soakConfig!),
      ],
      child: const NesdApp(),
    ),
  );
}

void _addLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield await _addLicense(
      'Ubuntu Mono font',
      'assets/fonts/UbuntuMono-LICENSE.txt',
    );
    yield await _addLicense('Inter font', 'assets/fonts/Inter-LICENSE.txt');
  });
}

Future<LicenseEntryWithLineBreaks> _addLicense(String name, String file) async {
  return LicenseEntryWithLineBreaks([name], await rootBundle.loadString(file));
}

Future<void> _migrateLinuxDevProfile(Directory applicationSupport) async {
  if (!Platform.isLinux || appFlavor != 'dev') {
    return;
  }

  final legacy = Directory(
    p.join(applicationSupport.parent.path, legacyLinuxApplicationId),
  );

  final migrated = await migrateDevProfile(
    target: applicationSupport,
    legacy: legacy,
  );

  if (migrated) {
    log.app.info(
      'Copied the profile from ${legacy.path} to ${applicationSupport.path}',
    );
  }
}
