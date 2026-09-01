import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_slot_registry.dart';

void main() {
  const dualSense = GamepadDeviceKey(
    name: 'Sony DualSense',
    vendorId: 1356,
    productId: 3302,
  );

  const eightBitDo = GamepadDeviceKey(
    name: '8BitDo Pro 2',
    vendorId: 11720,
    productId: 24832,
  );

  test('a device is unknown until a refresh finds it', () async {
    final directory = GamepadDeviceDirectory(
      lookup: () async => {'a': dualSense},
    );

    expect(directory.keyFor('a'), isNull);

    await directory.refresh();

    expect(directory.keyFor('a'), dualSense);
  });

  test('refresh returns the devices it found', () async {
    final directory = GamepadDeviceDirectory(
      lookup: () async => {'a': dualSense},
    );

    expect(await directory.refresh(), {'a': dualSense});
  });

  test('concurrent refreshes share a single lookup', () async {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    var calls = 0;

    final directory = GamepadDeviceDirectory(
      lookup: () {
        calls++;

        return lookup.future;
      },
    );

    final first = directory.refresh();
    final second = directory.refresh();

    lookup.complete({'a': dualSense});

    expect(await first, {'a': dualSense});
    expect(await second, {'a': dualSense});
    expect(calls, 1);
  });

  test('a refresh after the previous one completed looks up again', () async {
    var calls = 0;

    final directory = GamepadDeviceDirectory(
      lookup: () async {
        calls++;

        return {'a': dualSense};
      },
    );

    await directory.refresh();
    await directory.refresh();

    expect(calls, 2);
  });

  test('a failed lookup returns null and keeps the known devices', () async {
    var fail = false;

    final directory = GamepadDeviceDirectory(
      lookup: () async {
        if (fail) {
          throw Exception('no permission');
        }

        return {'a': dualSense};
      },
    );

    await directory.refresh();

    fail = true;

    expect(await directory.refresh(), isNull);
    expect(directory.keyFor('a'), dualSense);

    fail = false;

    expect(await directory.refresh(), {'a': dualSense});
  });

  test('a lookup that throws an Error is a failure like any other', () async {
    final directory = GamepadDeviceDirectory(
      lookup: () async => throw TypeError(),
    );

    expect(await directory.refresh(), isNull);
  });

  test('a device missing from a later refresh stays known', () async {
    var devices = {'a': dualSense, 'b': eightBitDo};

    final directory = GamepadDeviceDirectory(lookup: () async => devices);

    await directory.refresh();

    devices = {'a': dualSense};

    expect(await directory.refresh(), {'a': dualSense});
    expect(directory.keyFor('b'), eightBitDo);
  });

  test('a later refresh replaces a known key', () async {
    var devices = {'a': const GamepadDeviceKey(name: 'Sony DualSense')};

    final directory = GamepadDeviceDirectory(lookup: () async => devices);

    await directory.refresh();

    devices = {'a': dualSense};

    await directory.refresh();

    expect(directory.keyFor('a'), dualSense);
  });

  test('the mapper and the registry enumerate once for the same pad', () async {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    var calls = 0;

    final directory = GamepadDeviceDirectory(
      lookup: () {
        calls++;

        return lookup.future;
      },
    );

    final events = StreamController<GamepadEvent>();
    final registry = GamepadSlotRegistry(directory: directory);

    final mapper = GamepadInputMapper(
      directory: directory,
      events: events.stream,
      normalizer: GamepadNormalizer.forPlatform(GamepadPlatform.linux),
    );

    final subscription = mapper.stream.listen(
      (event) => registry.observe(event.gamepadId, event.deviceKey),
    );

    addTearDown(subscription.cancel);
    addTearDown(mapper.dispose);
    addTearDown(events.close);

    events.add(
      GamepadEvent(
        gamepadId: '0',
        timestamp: 0,
        type: KeyType.button,
        key: '0',
        value: 1,
      ),
    );

    await pumpEventQueue();

    lookup.complete({'0': dualSense});

    await pumpEventQueue();

    expect(registry.slotOf('0'), 0);
    expect(calls, 1);
  });
}
