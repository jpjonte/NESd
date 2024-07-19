import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        packageInfoProvider.overrideWithValue(packageInfo),
      ],
      child: const NesdApp(),
    ),
  );
}
