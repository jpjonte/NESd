import 'package:flutter/material.dart';

const baseTextStyle = TextStyle(fontFamily: 'Inter');

const nesdRedPrimary = 0xffdd2222;

const nesdRed = MaterialColor(nesdRedPrimary, {
  50: Color.fromARGB(0xff, 0xff, 0xee, 0xee),
  100: Color.fromARGB(0xff, 0xff, 0xcc, 0xcc),
  200: Color.fromARGB(0xff, 0xff, 0x99, 0x99),
  300: Color.fromARGB(0xff, 0xff, 0x66, 0x66),
  400: Color.fromARGB(0xff, 0xff, 0x33, 0x33),
  500: Color(nesdRedPrimary),
  600: Color.fromARGB(0xff, 0xcc, 0x00, 0x00),
  700: Color.fromARGB(0xff, 0x88, 0x00, 0x00),
  750: Color.fromARGB(0xff, 0x66, 0x00, 0x00),
  800: Color.fromARGB(0xff, 0x44, 0x00, 0x00),
  900: Color.fromARGB(0xff, 0x22, 0x00, 0x00),
});

final textTheme = TextTheme(
  bodyMedium: baseTextStyle.copyWith(fontSize: 12.0),
  bodyLarge: baseTextStyle.copyWith(fontSize: 16.0),
);

final sliderTheme = SliderThemeData(
  thumbColor: nesdRed[300],
  activeTrackColor: nesdRed[500],
  inactiveTrackColor: nesdRed[800],
);

final filledButtonTheme = FilledButtonThemeData(
  style: ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return nesdRed[500];
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.grey[900];
      }

      if (states.contains(WidgetState.pressed)) {
        return nesdRed[600];
      }

      return nesdRed[800];
    }),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shape: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return const StadiumBorder(side: BorderSide(color: Colors.white));
      }

      return const StadiumBorder();
    }),
    textStyle: WidgetStateProperty.resolveWith(
      (states) => baseTextStyle.copyWith(
        fontVariations: const [FontVariation.weight(700)],
      ),
    ),
  ),
);

final dividerTheme = DividerThemeData(
  color: nesdRed[700],
  space: 0,
  indent: 0,
  endIndent: 0,
);

final inputDecorationTheme = InputDecorationTheme(
  hintStyle: baseTextStyle.copyWith(color: Colors.grey[500]),
);

final segmentedButtonThemeLight = SegmentedButtonThemeData(
  style: SegmentedButton.styleFrom(
    foregroundColor: Colors.black,
    selectedBackgroundColor: nesdRed[600],
    selectedForegroundColor: Colors.white,
  ),
);

final focusColor = nesdRed[700]!;

final surfaceContainerColor = nesdRed[800]!;

final canvasColor = nesdRed[800]!;

final nesdThemeLight = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.light(
    primary: nesdRed,
    surfaceContainer: surfaceContainerColor,
  ),
  canvasColor: canvasColor,
  focusColor: focusColor,
  textTheme: textTheme,
  sliderTheme: sliderTheme,
  filledButtonTheme: filledButtonTheme,
  dividerTheme: dividerTheme,
  segmentedButtonTheme: segmentedButtonThemeLight,
);

final dialogThemeDark = DialogTheme(
  backgroundColor: nesdRed[900],
  shadowColor: nesdRed[600],
  elevation: 4,
);

final segmentedButtonThemeDark = SegmentedButtonThemeData(
  style: SegmentedButton.styleFrom(
    foregroundColor: Colors.white,
    selectedBackgroundColor: nesdRed[600],
    selectedForegroundColor: Colors.white,
  ),
);

final nesdThemeDark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.dark(
    primary: nesdRed,
    onPrimary: Colors.white,
    surface: Colors.black,
    surfaceContainer: surfaceContainerColor,
  ),
  canvasColor: canvasColor,
  focusColor: focusColor,
  textTheme: textTheme,
  sliderTheme: sliderTheme,
  filledButtonTheme: filledButtonTheme,
  dividerTheme: dividerTheme,
  dialogTheme: dialogThemeDark,
  inputDecorationTheme: inputDecorationTheme,
  segmentedButtonTheme: segmentedButtonThemeDark,
);
