import 'package:flutter/material.dart';

const baseTextStyle = TextStyle(fontFamily: 'Inter');

const nesdRedPrimary = 0xffdd2222;

const nesdRed = MaterialColor(nesdRedPrimary, {
  50: Color(0xffffc2c2),
  100: Color(0xffffa3a3),
  200: Color(0xffff8585),
  300: Color(0xffff6666),
  400: Color(0xfff54545),
  500: Color(nesdRedPrimary),
  600: Color(0xffbd1e1e),
  700: Color(0xff9e1919),
  750: Color(0xff801414),
  800: Color(0xff611010),
  900: Color(0xff420b0b),
});

final textTheme = TextTheme(
  headlineSmall: baseTextStyle.copyWith(
    fontSize: 22.0,
    fontVariations: const [FontVariation.weight(700)],
  ),
  bodySmall: baseTextStyle.copyWith(fontSize: 12.0),
  bodyMedium: baseTextStyle.copyWith(fontSize: 14.0),
  bodyLarge: baseTextStyle.copyWith(fontSize: 16.0),
);

final dividerTheme = DividerThemeData(
  color: nesdRed[700],
  space: 0,
  indent: 0,
  endIndent: 0,
);

const inputDecorationThemeBase = InputDecorationTheme(
  border: OutlineInputBorder(borderSide: BorderSide(width: 2)),
  enabledBorder: OutlineInputBorder(borderSide: BorderSide(width: 2)),
  focusedBorder: OutlineInputBorder(borderSide: BorderSide(width: 2)),
);

final progressTheme = ProgressIndicatorThemeData(
  color: nesdRed[500],
  circularTrackColor: nesdRed[800],
  linearTrackColor: nesdRed[800],
  refreshBackgroundColor: nesdRed[800],
  stopIndicatorColor: nesdRed[500],
);

final iconButtonThemeData = IconButtonThemeData(
  style: ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(20, 20)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
);

const tabBarThemeBase = TabBarThemeData(dividerHeight: 2);
