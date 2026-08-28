import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_mapper.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

class _MockInputMapper extends Mock implements GamepadInputMapper {}

GamepadInputEvent _dpadDown(double value) => GamepadInputEvent(
  gamepadId: '0',
  gamepadName: 'Test Pad',
  inputId: 'button_dpadDown',
  value: value,
  label: 'D-Pad Down',
);

void main() {
  test('accelerates hold-to-repeat while an input stays held', () {
    fakeAsync((async) {
      final events = StreamController<GamepadInputEvent>();
      final mapper = _MockInputMapper();

      when(() => mapper.stream).thenAnswer((_) => events.stream);

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              gamepadId: '0',
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
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

      final actionStream = ActionStream();

      final handler = GamepadInputHandler(
        [
          Binding(
            index: 0,
            action: inputDown,
            input: InputCombination.gamepad(
              gamepadId: '0',
              inputs: {const GamepadInput(id: 'button_dpadDown', direction: 1)},
            ),
          ),
        ],
        actionStream: actionStream,
        inputMapper: mapper,
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
}
