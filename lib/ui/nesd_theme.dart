import 'package:flutter/material.dart';

const nesdRed = Color.fromARGB(0xff, 0xdd, 0x22, 0x22);

const textTheme = TextTheme(
  bodyMedium: TextStyle(fontSize: 12.0),
);

const sliderTheme = SliderThemeData(
  thumbColor: Color.fromARGB(0xff, 0xee, 0x00, 0x00),
  activeTrackColor: Color.fromARGB(0xff, 0xcc, 0x00, 0x00),
  inactiveTrackColor: Color.fromARGB(0xff, 0x77, 0x00, 0x00),
);

final nesdThemeLight = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: nesdRed,
  ),
  textTheme: textTheme,
  sliderTheme: sliderTheme,
);

final nesdThemeDark = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: nesdRed,
    onPrimary: Colors.white,
    surface: Colors.black,
    // ignore: deprecated_member_use
    background: Colors.black,
  ),
  textTheme: textTheme,
  sliderTheme: sliderTheme,
);
