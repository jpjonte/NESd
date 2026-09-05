import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';

void main() {
  late StreamController<GamepadEvent> events;

  setUp(() {
    events = StreamController<GamepadEvent>();
  });

  tearDown(() => events.close());

  GamepadEvent event(
    String key, {
    KeyType type = KeyType.button,
    double value = 1.0,
    String gamepadId = '0',
  }) => GamepadEvent(
    gamepadId: gamepadId,
    timestamp: 0,
    type: type,
    key: key,
    value: value,
  );

  GamepadInputMapper mapper(
    GamepadPlatform platform, {
    GamepadDeviceLookup? deviceLookup,
    bool scaleAnalogFallback = false,
  }) {
    final mapper = GamepadInputMapper(
      events: events.stream,
      normalizer: GamepadNormalizer.forPlatform(platform),
      directory: GamepadDeviceDirectory(lookup: deviceLookup ?? () async => {}),
      scaleAnalogFallback: scaleAnalogFallback,
    );

    addTearDown(mapper.dispose);

    return mapper;
  }

  Future<List<GamepadInputEvent>> emit(
    GamepadInputMapper mapper,
    List<GamepadEvent> raw,
  ) async {
    final collected = <GamepadInputEvent>[];
    final subscription = mapper.stream.listen(collected.add);

    raw.forEach(events.add);

    await pumpEventQueue();
    await subscription.cancel();

    return collected;
  }

  group('normalized events', () {
    test('maps Android buttons to normalized ids', () async {
      final result = await emit(mapper(GamepadPlatform.android), [
        event('KEYCODE_BUTTON_A'),
      ]);

      expect(result.single.inputId, 'button_a');
      expect(result.single.value, 1.0);
      expect(result.single.label, 'A');
    });

    test('maps Android sticks to normalized axes', () async {
      final result = await emit(mapper(GamepadPlatform.android), [
        event('AXIS_Y', type: KeyType.analog, value: 0.5),
      ]);

      expect(result.single.inputId, 'axis_leftStickY');
      expect(result.single.value, 0.5);
    });

    test('maps macOS sticks to normalized axes', () async {
      final result = await emit(mapper(GamepadPlatform.macos), [
        event('l.joystick - xAxis', type: KeyType.analog, value: 0.7),
      ]);

      expect(result.single.inputId, 'axis_leftStickX');
      expect(result.single.value, 0.7);
    });

    test('maps Windows GameInput keys to normalized ids', () async {
      final result = await emit(mapper(GamepadPlatform.windows), [
        event('view'),
        event('leftThumbstickX', type: KeyType.analog, value: 0.5),
      ]);

      expect(result, hasLength(2));
      expect(result[0].inputId, 'button_back');
      expect(result[1].inputId, 'axis_leftStickX');
      expect(result[1].value, 0.5);
    });
  });

  group('d-pad regression guard (#118)', () {
    test('Android hat axes produce discrete directions', () async {
      final result = await emit(mapper(GamepadPlatform.android), [
        event('AXIS_HAT_X', type: KeyType.analog, value: -1),
        event('AXIS_HAT_Y', type: KeyType.analog),
      ]);

      final pressed = result.where((e) => e.value == 1.0);

      expect(pressed.map((e) => e.inputId), [
        'button_dpadLeft',
        'button_dpadUp',
      ]);
    });

    test('macOS d-pad axes produce discrete directions', () async {
      final result = await emit(mapper(GamepadPlatform.macos), [
        event('dpad - xAxis', type: KeyType.analog),
        event('dpad - yAxis', type: KeyType.analog),
      ]);

      final pressed = result.where((e) => e.value == 1.0);

      expect(pressed.map((e) => e.inputId), [
        'button_dpadRight',
        'button_dpadUp',
      ]);
    });

    test('Linux hat axes produce discrete directions', () async {
      final result = await emit(mapper(GamepadPlatform.linux), [
        event('6', type: KeyType.analog, value: -32767),
        event('7', type: KeyType.analog, value: 32767),
      ]);

      final pressed = result.where((e) => e.value == 1.0);

      expect(pressed.map((e) => e.inputId), [
        'button_dpadLeft',
        'button_dpadDown',
      ]);
    });

    test('Windows d-pad buttons keep discrete directions', () async {
      final result = await emit(mapper(GamepadPlatform.windows), [
        event('dpadUp'),
        event('dpadLeft'),
      ]);

      expect(result.map((e) => e.inputId), [
        'button_dpadUp',
        'button_dpadLeft',
      ]);
    });
  });

  group('raw fallback', () {
    test('keeps raw ids for unmapped buttons', () async {
      final result = await emit(mapper(GamepadPlatform.linux), [event('11')]);

      expect(result.single.inputId, 'button_11');
      expect(result.single.value, 1.0);
      expect(result.single.label, '11');
    });

    test('scales unmapped analog values when enabled', () async {
      final result = await emit(
        mapper(GamepadPlatform.linux, scaleAnalogFallback: true),
        [event('8', type: KeyType.analog, value: 16384)],
      );

      expect(result.single.inputId, 'analog_8');
      expect(result.single.value, closeTo(0.5, 0.001));
    });

    test('does not scale unmapped button values', () async {
      final result = await emit(
        mapper(GamepadPlatform.linux, scaleAnalogFallback: true),
        [event('11')],
      );

      expect(result.single.value, 1.0);
    });
  });

  group('gamepad names', () {
    test('resolves names asynchronously', () async {
      final gamepadMapper = mapper(
        GamepadPlatform.android,
        deviceLookup: () async => {
          '0': const GamepadDeviceKey(name: 'Test Pad'),
        },
      );

      final first = await emit(gamepadMapper, [event('KEYCODE_BUTTON_A')]);
      final second = await emit(gamepadMapper, [event('KEYCODE_BUTTON_A')]);

      expect(first.single.gamepadName, 'Unknown');
      expect(second.single.gamepadName, 'Test Pad');
    });

    test('keeps emitting events when the names lookup fails', () async {
      final gamepadMapper = mapper(
        GamepadPlatform.android,
        deviceLookup: () async => throw Exception('no permission'),
      );

      final result = await emit(gamepadMapper, [event('KEYCODE_BUTTON_A')]);

      expect(result.single.gamepadName, 'Unknown');
    });
  });

  group('sensor devices', () {
    test('drops events from motion-sensor devices', () async {
      final gamepadMapper = mapper(
        GamepadPlatform.linux,
        deviceLookup: () async => {
          '0': const GamepadDeviceKey(name: 'DualSense Wireless Controller'),
          '1': const GamepadDeviceKey(
            name: 'DualSense Wireless Controller Motion Sensors',
          ),
        },
      );

      // Warm the name cache before asserting on the filter.
      await emit(gamepadMapper, [event('0')]);

      final result = await emit(gamepadMapper, [
        event('3', type: KeyType.analog, value: 128, gamepadId: '1'),
        event('1'),
      ]);

      expect(result.map((e) => e.inputId), ['button_b']);
    });

    test('keeps devices whose name merely contains a sensor word', () async {
      final gamepadMapper = mapper(
        GamepadPlatform.linux,
        deviceLookup: () async => {
          '0': const GamepadDeviceKey(name: 'Optimus Pad'),
        },
      );

      // Warm the name cache before asserting on the filter.
      await emit(gamepadMapper, [event('0')]);

      final result = await emit(gamepadMapper, [event('1')]);

      expect(result.single.inputId, 'button_b');
    });
  });

  group('device info', () {
    test('forwards vendor and product ids onto emitted events', () async {
      final m = mapper(GamepadPlatform.linux);

      final emitted = await emit(m, [
        GamepadEvent(
          gamepadId: '0',
          timestamp: 0,
          type: KeyType.button,
          key: '0',
          value: 1,
          vendorId: 1356,
          productId: 3302,
        ),
      ]);

      expect(emitted.single.vendorId, 1356);
      expect(emitted.single.productId, 3302);
    });

    test('builds a device key from the event and the lookup name', () async {
      final m = mapper(
        GamepadPlatform.linux,
        deviceLookup: () async => {
          '0': const GamepadDeviceKey(name: 'Test Pad'),
        },
      );

      // The first event triggers the async lookup; the second sees it.
      await emit(m, [event('0')]);

      final emitted = await emit(m, [
        GamepadEvent(
          gamepadId: '0',
          timestamp: 0,
          type: KeyType.button,
          key: '0',
          value: 1,
          vendorId: 1356,
          productId: 3302,
        ),
      ]);

      expect(
        emitted.single.deviceKey,
        const GamepadDeviceKey(
          name: 'Test Pad',
          vendorId: 1356,
          productId: 3302,
        ),
      );
    });
  });
}
