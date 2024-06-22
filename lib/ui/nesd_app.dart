import 'package:flutter/material.dart';
import 'package:nes/ui/emulator/emulator_screen.dart';
import 'package:nes/ui/nesd_theme.dart';
import 'package:nes/ui/settings/settings_screen.dart';

class NesdApp extends StatelessWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NESd',
      theme: nesdThemeLight,
      darkTheme: nesdThemeDark,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => const Scaffold(body: EmulatorScreen()),
        SettingsScreen.route: (_) => const SettingsScreen(),
      },
    );
  }
}
