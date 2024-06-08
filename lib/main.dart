import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/app.dart';

void main() {
  runApp(const ProviderScope(child: NesdApp()));
}

class NesdApp extends StatelessWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NESd',
      theme: ThemeData(
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
      home: const Scaffold(
        body: AppWidget(),
      ),
    );
  }
}
