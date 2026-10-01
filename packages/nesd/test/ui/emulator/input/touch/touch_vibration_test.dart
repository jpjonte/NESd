import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _center = Offset(400, 300);

const _up = Offset(0, -55);
const _right = Offset(55, 0);
const _upRight = Offset(55, -55);

Future<List<String>> _pumpControls(
  WidgetTester tester,
  Map<String, dynamic> control, {
  bool? touchVibration,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings': jsonEncode({'touchVibration': ?touchVibration}),
  });

  final prefs = await SharedPreferences.getInstance();

  final haptics = <String>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }

      return null;
    },
  );

  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  final config = [
    TouchInputConfig.fromJson({'x': 0.0, 'y': 0.0, ...control}),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: TouchControls(portraitConfig: config, landscapeConfig: config),
        ),
      ),
    ),
  );

  return haptics;
}

Future<void> _drag(WidgetTester tester, List<Offset> path) async {
  final gesture = await tester.startGesture(_center);

  for (final target in path) {
    await gesture.moveTo(_center + target);
    await tester.pump();
  }

  await gesture.up();
  await tester.pump();
}

void main() {
  const button = {'type': 'circleButton', 'action': 'controller1.a'};

  const directions = {
    'upAction': 'controller1.up',
    'downAction': 'controller1.down',
    'leftAction': 'controller1.left',
    'rightAction': 'controller1.right',
  };

  testWidgets('a button press vibrates lightly by default', (tester) async {
    final haptics = await _pumpControls(tester, button);

    final gesture = await tester.startGesture(_center);
    await tester.pump();

    expect(haptics, ['HapticFeedbackType.lightImpact']);

    await gesture.up();
    await tester.pump();

    expect(haptics, hasLength(1));
  });

  testWidgets('disabled touch vibration never vibrates', (tester) async {
    final haptics = await _pumpControls(tester, {
      'type': 'dPad',
      ...directions,
    }, touchVibration: false);

    await _drag(tester, [_up, _right]);

    final buttonHaptics = await _pumpControls(
      tester,
      button,
      touchVibration: false,
    );

    await tester.tapAt(_center);
    await tester.pump();

    expect(haptics, isEmpty);
    expect(buttonHaptics, isEmpty);
  });

  testWidgets('the d-pad vibrates once per newly pressed direction', (
    tester,
  ) async {
    final haptics = await _pumpControls(tester, {
      'type': 'dPad',
      ...directions,
    });

    await _drag(tester, [_up, _up + const Offset(0, -10), Offset.zero, _right]);

    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  testWidgets('the joystick vibrates once per newly pressed direction', (
    tester,
  ) async {
    final haptics = await _pumpControls(tester, {
      'type': 'joyStick',
      ...directions,
    });

    await _drag(tester, [_up, _up + const Offset(0, -10), _upRight]);

    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });
}
