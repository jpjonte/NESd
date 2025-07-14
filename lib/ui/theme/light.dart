import 'package:flutter/material.dart';
import 'package:nesd/ui/theme/base.dart';

final sliderTheme = SliderThemeData(
  thumbColor: nesdRed[300],
  thumbShape: const RoundSliderThumbShape(elevation: 0),
  activeTrackColor: nesdRed[300],
  inactiveTrackColor: nesdRed[700],
);

final filledButtonTheme = FilledButtonThemeData(
  style: ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      return nesdRed[500];
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.grey[500];
      }

      if (states.contains(WidgetState.pressed)) {
        return nesdRed[400];
      }

      return nesdRed[700];
    }),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shape: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return StadiumBorder(side: BorderSide(width: 2, color: nesdRed[700]!));
      }

      return const StadiumBorder();
    }),
    textStyle: WidgetStateProperty.all(
      baseTextStyle.copyWith(fontVariations: const [FontVariation.weight(700)]),
    ),
  ),
);

final dialogThemeLight = DialogThemeData(
  backgroundColor: nesdRed[900],
  shadowColor: nesdRed[600],
  titleTextStyle: baseTextStyle.copyWith(color: Colors.white, fontSize: 20),
  contentTextStyle: baseTextStyle.copyWith(color: Colors.white),
  elevation: 4,
);

final inputDecorationTheme = inputDecorationThemeBase.copyWith(
  hintStyle: baseTextStyle.copyWith(color: Colors.grey[500]),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  ),
  focusColor: Colors.white,
);

final segmentedButtonTheme = SegmentedButtonThemeData(
  style: SegmentedButton.styleFrom(
    foregroundColor: Colors.black,
    backgroundColor: Colors.white,
    selectedBackgroundColor: nesdRed[600],
    selectedForegroundColor: Colors.white,
    side: const BorderSide(width: 2),
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

    return Colors.black;
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

    return Colors.black;
  }),
);

const appBarTheme = AppBarTheme(
  backgroundColor: Colors.white,
  foregroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  iconTheme: IconThemeData(color: Colors.black),
);

final tabBarTheme = tabBarThemeBase.copyWith(
  overlayColor: WidgetStateProperty.all(Colors.white),
);

final checkboxTheme = CheckboxThemeData(
  fillColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return Colors.grey[500];
    }

    if (states.contains(WidgetState.selected)) {
      return nesdRed[500];
    }

    return Colors.transparent;
  }),
  checkColor: WidgetStateProperty.all(Colors.white),
  side: const BorderSide(width: 2, color: Colors.white),
);

final nesdThemeLight = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.light(
    primary: nesdRed,
    onPrimaryContainer: Colors.white,
    surfaceContainer: nesdRed[700],
  ),
  canvasColor: nesdRed[700],
  focusColor: nesdRed[500],
  textTheme: textTheme,
  sliderTheme: sliderTheme,
  filledButtonTheme: filledButtonTheme,
  dividerTheme: dividerTheme,
  hoverColor: nesdRed[400]!.withAlpha(0x66),
  dialogTheme: dialogThemeLight,
  inputDecorationTheme: inputDecorationTheme,
  segmentedButtonTheme: segmentedButtonTheme,
  progressIndicatorTheme: progressTheme,
  iconButtonTheme: iconButtonThemeData,
  switchTheme: switchTheme,
  tabBarTheme: tabBarTheme,
  appBarTheme: appBarTheme,
  disabledColor: Colors.grey[500],
  checkboxTheme: checkboxTheme,
);
