import 'package:flutter/material.dart';
import 'package:nes/ui/emulator/emulator_screen.dart';
import 'package:nes/ui/settings/settings_screen.dart';

class NesdApp extends StatelessWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NESd',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.red),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12.0),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          surface: Colors.black,
          // ignore: deprecated_member_use
          background: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12.0),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => const Scaffold(body: EmulatorScreen()),
        SettingsScreen.route: (_) => const SettingsScreen(),
      },
    );
  }
}
