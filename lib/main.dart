import 'package:flutter/material.dart';
import 'package:nes/ui/app.dart';

void main() {
  runApp(const NesdApp());
}

class NesdApp extends StatelessWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NESd',
      theme: ThemeData(
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
