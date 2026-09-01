import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_slot_registry.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

class _MockInputMapper extends Mock implements GamepadInputMapper {}

GamepadSlotRegistry _emptyRegistry() => GamepadSlotRegistry(
  directory: GamepadDeviceDirectory(lookup: () async => {}),
);

GamepadInputEvent _dpadDown(double value) => GamepadInputEvent(
  gamepadId: '0',
  gamepadName: 'Test Pad',
  inputId: 'button_dpadDown',
  value: value,
  label: 'D-Pad Down',
);

GamepadInputEvent _buttonA(double value) => GamepadInputEvent(
  gamepadId: '0',
  gamepadName: 'Test Pad',
  inputId: 'button_a',
  value: value,
  label: 'A',
);

GamepadInputEvent _leftStickY(double value) => GamepadInputEvent(
  gamepadId: '0',
  gamepadName: 'Test Pad',
  inputId: 'axis_leftStickY',
  value: value,
  label: 'Left Stick Y',
);

void main() {
  test('accelerates hold-to-repeat while an input stays held', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();

      // ignore: cascade_invocations
      registry.observe('0', const GamepadDeviceKey(name: 'Test Pad'));

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final times = <Duration>[];

      final subscription = actionStream.stream.listen((event) {
        if (event.value > 0.5) {
          times.add(async.elapsed);
        }
      });

      events.add(_dpadDown(1));
      async.flushMicrotasks();

      expect(times, hasLength(1), reason: 'the press itself emits once');

      async.elapse(const Duration(milliseconds: 499));

      expect(times, hasLength(1), reason: 'no repeats during the delay');

      async.elapse(const Duration(milliseconds: 3501));

      expect(times.length, greaterThan(5), reason: 'holding repeats');

      final intervals = [
        for (var i = 2; i < times.length; i++) times[i] - times[i - 1],
      ];

      for (var i = 1; i < intervals.length; i++) {
        expect(
          intervals[i],
          lessThanOrEqualTo(intervals[i - 1]),
          reason: 'repeat intervals never grow while held',
        );
      }

      expect(intervals.first.inMilliseconds, greaterThan(50));
      expect(
        intervals.last,
        const Duration(milliseconds: 33),
        reason: 'a sustained hold bottoms out at the floor',
      );
      expect(
        intervals[intervals.length - 2],
        intervals.last,
        reason: 'the floor is a plateau, not a passing value',
      );

      events.add(_dpadDown(0));
      async.flushMicrotasks();

      final countAfterRelease = times.length;

      async.elapse(const Duration(seconds: 1));

      expect(
        times,
        hasLength(countAfterRelease),
        reason: 'release stops repeating',
      );

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('dispose stops hold-to-repeat', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();

      // ignore: cascade_invocations
      registry.observe('0', const GamepadDeviceKey(name: 'Test Pad'));

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      var count = 0;

      final subscription = actionStream.stream.listen((_) => count++);

      events.add(_dpadDown(1));

      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 1));

      expect(count, greaterThan(1), reason: 'holding repeats');

      handler.dispose();

      final countAfterDispose = count;

      async.elapse(const Duration(seconds: 1));

      expect(count, countAfterDispose);

      subscription.cancel();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('resolves a slot binding to the pad in that slot', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();

      // ignore: cascade_invocations
      registry.observe('pad-b', const GamepadDeviceKey(name: 'B'));

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final fired = <InputAction>[];

      final subscription = actionStream.stream.listen((e) {
        if (e.value > 0.5) {
          fired.add(e.action);
        }
      });

      events.add(
        const GamepadInputEvent(
          gamepadId: 'pad-b',
          gamepadName: 'B',
          inputId: 'button_dpadDown',
          value: 1,
          label: 'D-Pad Down',
        ),
      );

      async.flushMicrotasks();

      expect(fired, [inputDown]);

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('releasing a pad turns off the action it was holding', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();
      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final fired = <InputActionEvent>[];

      final subscription = actionStream.stream.listen(fired.add);

      events.add(_dpadDown(1));
      async.flushMicrotasks();

      expect(fired.single.value, 1);

      fired.clear();

      registry.releaseAllExcept({});
      async.flushMicrotasks();

      expect(fired.map((e) => (e.action, e.value)), [
        (inputDown, 0.0),
      ], reason: 'unplugging a pad releases the button it was holding');

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('a pad that comes back is not still holding its old button', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();
      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final fired = <InputActionEvent>[];

      final subscription = actionStream.stream.listen(fired.add);

      events.add(_dpadDown(1));
      async.flushMicrotasks();

      registry
        ..releaseAllExcept({})
        ..observe('0', const GamepadDeviceKey(name: 'Test Pad'));

      async.flushMicrotasks();
      fired.clear();

      async.elapse(const Duration(seconds: 2));

      expect(
        fired,
        isEmpty,
        reason: 'the held state is dropped when the pad disappears',
      );

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('one button drives every default action bound to it', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();
      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        defaultGamepadBindings,
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final fired = <InputAction>[];

      final subscription = actionStream.stream.listen((e) {
        if (e.value > 0.5) {
          fired.add(e.action);
        }
      });

      events.add(_buttonA(1));
      async.flushMicrotasks();

      expect(
        fired,
        containsAll([controller1B, confirm]),
        reason: 'the same button is bound to a game and a menu action',
      );

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('an axis flip does not leave the opposite direction held', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();
      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputUp,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {const GamepadInput(id: 'axis_leftStickY', direction: 1)},
            ),
          ),
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 0,
              inputs: {
                const GamepadInput(id: 'axis_leftStickY', direction: -1),
              },
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final released = <InputAction>[];

      final subscription = actionStream.stream.listen((e) {
        if (e.value == 0) {
          released.add(e.action);
        }
      });

      events.add(_leftStickY(0.9));
      async.flushMicrotasks();

      // A stick can jump between extremes without a sample near zero.
      events.add(_leftStickY(-0.9));
      async.flushMicrotasks();

      events.add(_leftStickY(0));
      async.flushMicrotasks();

      expect(released, [
        inputDown,
      ], reason: 'only the direction the stick ended up in was still held');

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });

  test('ignores input for a slot that has no pad', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final registry = _emptyRegistry();

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              slot: 3,
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
        slotRegistry: registry,
      );

      final fired = <InputAction>[];

      final subscription = actionStream.stream.listen(
        (e) => fired.add(e.action),
      );

      events.add(
        const GamepadInputEvent(
          gamepadId: 'pad-a',
          gamepadName: 'A',
          inputId: 'button_dpadDown',
          value: 1,
          label: 'D-Pad Down',
        ),
      );

      async.flushMicrotasks();

      expect(fired, isEmpty);

      subscription.cancel();
      handler.dispose();
      events.close();
      async.flushMicrotasks();
    });
  });
}
