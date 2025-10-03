import 'package:flutter/material.dart';
import 'package:nesd/ui/theme/base.dart';

final sliderTheme = SliderThemeData(
  thumbColor: nesdRed[300],
  activeTrackColor: nesdRed[400],
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

final dialogTheme = DialogThemeData(
  backgroundColor: nesdRed[900],
  shadowColor: nesdRed[600],
  elevation: 4,
);

final inputDecorationTheme = inputDecorationThemeBase.copyWith(
  hintStyle: baseTextStyle.copyWith(color: Colors.grey[500]),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  ),
  focusColor: Colors.white,
);

final segmentedButtonTheme = SegmentedButtonThemeData(
  style: SegmentedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.black,
    selectedBackgroundColor: nesdRed[600],
    selectedForegroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 2),
  ),
);

final switchTheme = SwitchThemeData(
  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return Colors.grey[500];
    }

    if (states.contains(WidgetState.selected)) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return Colors.white;
      }

      return nesdRed;
    }

    return Colors.white;
  }),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return Colors.grey[500];
    }

    if (states.contains(WidgetState.selected)) {
      return nesdRed[500];
    }

    return null;
  }),
  thumbColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return Colors.grey[500];
    }

    if (states.contains(WidgetState.selected)) {
      if (states.contains(WidgetState.hovered)) {
        return nesdRed[100];
      }

      return Colors.white;
    }

    return Colors.white;
  }),
);

final nesdThemeDark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.dark(
    primary: nesdRed,
    onPrimary: Colors.white,
    surface: Colors.black,
    surfaceContainer: nesdRed[800],
  ),
  canvasColor: nesdRed[800],
  focusColor: nesdRed[700],
  textTheme: textTheme,
  sliderTheme: sliderTheme,
  filledButtonTheme: filledButtonTheme,
  dividerTheme: dividerTheme,
  dialogTheme: dialogTheme,
  inputDecorationTheme: inputDecorationTheme,
  segmentedButtonTheme: segmentedButtonTheme,
  progressIndicatorTheme: progressTheme,
  iconButtonTheme: iconButtonThemeData,
  tabBarTheme: tabBarThemeBase,
  switchTheme: switchTheme,
);
