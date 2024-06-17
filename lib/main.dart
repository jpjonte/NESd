import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/app.dart';
import 'package:nes/ui/settings_screen.dart';
import 'package:nes/ui/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const NesdApp(),
    ),
  );
}

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
        '/': (_) => const Scaffold(body: AppWidget()),
        SettingsScreen.route: (_) => const SettingsScreen(),
      },
    );
  }
}
