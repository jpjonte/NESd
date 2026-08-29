import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/controller.dart';

void main() {
  group('Controller', () {
    late Controller controller;

    setUp(() {
      controller = Controller();
    });

    bool isPressed(NesButton button) {
      controller
        ..write(0x4016, 1)
        ..write(0x4016, 0);

      for (var i = 0; i < button.index; i++) {
        controller.read(0x4016);
      }

      return controller.read(0x4016) == 1;
    }

    test('reports a held button as pressed', () {
      controller.buttonDown(NesButton.a);

      expect(isPressed(NesButton.a), isTrue);
    });

    test('reports a turbo button as pressed while the pulse is on', () {
      controller
        ..turboPhase = true
        ..buttonDown(NesButton.a, turbo: true);

      expect(isPressed(NesButton.a), isTrue);
    });

    test('reports a turbo button as released while the pulse is off', () {
      controller
        ..turboPhase = false
        ..buttonDown(NesButton.a, turbo: true);

      expect(isPressed(NesButton.a), isFalse);
    });

    test('keeps a normally held button pressed while the pulse is off', () {
      controller
        ..turboPhase = false
        ..buttonDown(NesButton.a)
        ..buttonDown(NesButton.a, turbo: true);

      expect(isPressed(NesButton.a), isTrue);
    });

    test('releasing turbo leaves the normal press untouched', () {
      controller
        ..turboPhase = true
        ..buttonDown(NesButton.a)
        ..buttonDown(NesButton.a, turbo: true)
        ..buttonUp(NesButton.a, turbo: true);

      expect(isPressed(NesButton.a), isTrue);
    });

    test('releasing the normal press leaves turbo pulsing', () {
      controller
        ..turboPhase = true
        ..buttonDown(NesButton.a)
        ..buttonDown(NesButton.a, turbo: true)
        ..buttonUp(NesButton.a);

      expect(isPressed(NesButton.a), isTrue);

      controller.turboPhase = false;

      expect(isPressed(NesButton.a), isFalse);
    });

    test('toggles turbo independently of the normal press', () {
      controller
        ..turboPhase = true
        ..buttonToggle(NesButton.b, turbo: true);

      expect(isPressed(NesButton.b), isTrue);

      controller.buttonToggle(NesButton.b, turbo: true);

      expect(isPressed(NesButton.b), isFalse);
    });

    test('leaves other buttons unaffected by a turbo press', () {
      controller
        ..turboPhase = true
        ..buttonDown(NesButton.a, turbo: true);

      expect(isPressed(NesButton.b), isFalse);
    });
  });
}
