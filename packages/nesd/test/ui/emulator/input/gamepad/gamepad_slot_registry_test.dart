import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
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

  GamepadSlotRegistry registry({
    Map<int, GamepadDeviceKey> remembered = const {},
    Map<String, GamepadDeviceKey> devices = const {},
  }) => GamepadSlotRegistry(
    remembered: remembered,
    directory: GamepadDeviceDirectory(lookup: () async => devices),
  );

  test('assigns the first unknown pad to slot 0', () {
    final r = registry();

    expect(r.observe('a', dualSense), 0);
    expect(r.gamepadIdFor(0), 'a');
    expect(r.slotOf('a'), 0);
  });

  test('assigns a second pad to the next free slot', () {
    final r = registry();

    // ignore: cascade_invocations
    r.observe('a', dualSense);

    expect(r.observe('b', eightBitDo), 1);
  });

  test('re-observing an assigned pad keeps its slot', () {
    final r = registry();

    // ignore: cascade_invocations
    r.observe('a', dualSense);

    expect(r.observe('a', dualSense), 0);
  });

  test('prefers a free remembered slot over the lowest free slot', () {
    final r = registry(remembered: {1: dualSense});

    expect(r.observe('a', dualSense), 1);
  });

  test("prefers each pad's remembered slot when both are free", () {
    final r = registry(remembered: {0: dualSense, 1: eightBitDo});

    // ignore: cascade_invocations
    r
      ..observe('b', eightBitDo)
      ..observe('a', dualSense);

    expect(r.slotOf('b'), 1);
    expect(r.slotOf('a'), 0);
  });

  test('falls back to lowest free when its remembered slot is taken', () {
    final r = registry(remembered: {0: eightBitDo});

    // ignore: cascade_invocations
    r.observe('a', dualSense);

    expect(r.observe('b', eightBitDo), 1);
  });

  test('takes the lowest slot when several remember the same key', () {
    final r = registry(remembered: {0: dualSense, 2: dualSense});

    expect(r.observe('a', dualSense), 0);
  });

  test('gives two identical pads distinct slots', () {
    final r = registry(remembered: {0: dualSense});

    expect(r.observe('a', dualSense), 0);
    expect(r.observe('b', dualSense), 1);
  });

  test('matches a name-only remembered key and upgrades it', () {
    final r = registry(
      remembered: {1: const GamepadDeviceKey(name: 'Sony DualSense')},
    );

    expect(r.observe('a', dualSense), 1);
    expect(r.remembered[1], dualSense);
  });

  test('does not remember a pad whose name has not arrived yet', () {
    final r = registry();

    // ignore: cascade_invocations
    r.observe('a', const GamepadDeviceKey(name: unknownGamepadName));

    expect(r.remembered, isEmpty);
  });

  test('a placeholder does not overwrite a remembered name', () {
    const remembered = GamepadDeviceKey(name: 'Sony DualSense');

    final r = registry(remembered: {0: remembered});

    // ignore: cascade_invocations
    r.observe('a', const GamepadDeviceKey(name: unknownGamepadName));

    expect(r.remembered[0], remembered);
  });

  test("a pad's real name replaces the placeholder it was observed with", () {
    const real = GamepadDeviceKey(name: 'Sony DualSense');

    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', const GamepadDeviceKey(name: unknownGamepadName))
      ..observe('a', real);

    expect(r.assignments.single.key, real);
    expect(r.remembered[0], real);
  });

  test("a named key replaces the placeholder a pad's first event carried", () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe(
        'a',
        const GamepadDeviceKey(
          name: unknownGamepadName,
          vendorId: 1356,
          productId: 3302,
        ),
      )
      ..observe('a', dualSense);

    expect(r.assignments.single.key, dualSense);
    expect(r.remembered[0], dualSense);
  });

  test('ids upgrade an already-assigned name-only key', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', const GamepadDeviceKey(name: 'Sony DualSense'))
      ..observe('a', dualSense);

    expect(r.assignments.single.key, dualSense);
    expect(r.remembered[0], dualSense);
  });

  test('a weaker key does not replace a known one', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('a', const GamepadDeviceKey(name: unknownGamepadName));

    expect(r.assignments.single.key, dualSense);
    expect(r.remembered[0], dualSense);
  });

  test('seed assigns every listed device', () async {
    final r = registry(devices: {'a': dualSense, 'b': eightBitDo});

    await r.seed();

    expect(r.slotOf('a'), isNotNull);
    expect(r.slotOf('b'), isNotNull);
    expect(r.slotOf('a'), isNot(r.slotOf('b')));
  });

  test('seed keeps a pad observed while its lookup was in flight', () async {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    final r = GamepadSlotRegistry(
      directory: GamepadDeviceDirectory(lookup: () => lookup.future),
    );

    final seeding = r.seed();

    r.observe('a', dualSense);

    lookup.complete({});

    await seeding;

    expect(r.slotOf('a'), 0);
  });

  test('a reconcile keeps a pad observed while it was in flight', () async {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    final r = GamepadSlotRegistry(
      directory: GamepadDeviceDirectory(lookup: () => lookup.future),
    );

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('b', eightBitDo);

    lookup.complete({'a': dualSense});

    await pumpEventQueue();

    expect(r.slotOf('b'), 1);
  });

  test('seed still releases a pad that is no longer connected', () async {
    final r = registry(devices: {'b': eightBitDo});

    // ignore: cascade_invocations
    r.observe('a', dualSense);

    await pumpEventQueue();
    await r.seed();

    expect(r.slotOf('a'), isNull);
    expect(r.slotOf('b'), 0);
  });

  test('a disposed registry does not notify when seed completes', () async {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    final r = GamepadSlotRegistry(
      directory: GamepadDeviceDirectory(lookup: () => lookup.future),
    );

    final seeding = r.seed();

    r
      ..observe('a', dualSense)
      ..dispose();

    lookup.complete({});

    await expectLater(seeding, completes);
  });

  test('a disposed registry does not notify when a reconcile completes', () {
    final lookup = Completer<Map<String, GamepadDeviceKey>>();
    final r = GamepadSlotRegistry(
      directory: GamepadDeviceDirectory(lookup: () => lookup.future),
    );

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('b', eightBitDo)
      ..dispose();

    lookup.complete({'a': dualSense});

    return expectLater(pumpEventQueue(), completes);
  });

  test('releaseAllExcept frees slots for absent devices', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('b', eightBitDo)
      ..releaseAllExcept({'b'});

    expect(r.slotOf('a'), isNull);
    expect(r.slotOf('b'), 1);
  });

  test('a released slot is reused by the next unknown pad', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..releaseAllExcept({});

    expect(r.observe('b', eightBitDo), 0);
  });

  test('a pad observed with an empty device lookup keeps its slot '
      'after reconcile completes', () async {
    final r = registry();

    // ignore: cascade_invocations
    r.observe('a', dualSense);

    await pumpEventQueue();

    expect(r.slotOf('a'), 0);
    expect(r.gamepadIdFor(0), 'a');
  });

  test('assign moves a pad to a free slot', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..assign(3, 'a');

    expect(r.slotOf('a'), 3);
    expect(r.gamepadIdFor(0), isNull);
    expect(r.remembered[3], dualSense);
  });

  test("assign forgets the pad's old remembered slot", () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..assign(3, 'a');

    expect(r.remembered.containsKey(0), isFalse);
    expect(r.remembered[3], dualSense);
  });

  test('assign swaps when the target slot is occupied', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('b', eightBitDo)
      ..assign(0, 'b');

    expect(r.slotOf('b'), 0);
    expect(r.slotOf('a'), 1);
  });

  test('assign is a no-op for an unobserved pad', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..assign(0, 'ghost');

    expect(r.slotOf('a'), 0);
    expect(r.slotOf('ghost'), isNull);
  });

  test('assignments are sorted by slot', () {
    final r = registry();

    // ignore: cascade_invocations
    r
      ..observe('a', dualSense)
      ..observe('b', eightBitDo)
      ..assign(5, 'a');

    expect(r.assignments.map((a) => a.slot), [1, 5]);
  });

  test('notifies listeners when an assignment changes', () {
    final r = registry();
    var notifications = 0;

    r
      ..addListener(() => notifications++)
      ..observe('a', dualSense);

    expect(notifications, 1);
  });

  test('does not notify when re-observing an assigned pad', () {
    final r = registry();
    var notifications = 0;

    r
      ..observe('a', dualSense)
      ..addListener(() => notifications++)
      ..observe('a', dualSense);

    expect(notifications, 0);
  });
}
