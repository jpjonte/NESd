import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';

void main() {
  const withIds = GamepadDeviceKey(
    name: 'Sony DualSense',
    vendorId: 1356,
    productId: 3302,
  );

  const nameOnly = GamepadDeviceKey(name: 'Sony DualSense');

  group('matches', () {
    test('compares ids when both keys have them', () {
      const other = GamepadDeviceKey(
        name: 'Renamed Pad',
        vendorId: 1356,
        productId: 3302,
      );

      expect(withIds.matches(other), isTrue);
    });

    test('rejects different ids even when names agree', () {
      const other = GamepadDeviceKey(
        name: 'Sony DualSense',
        vendorId: 1118,
        productId: 765,
      );

      expect(withIds.matches(other), isFalse);
    });

    test('falls back to the name when either key lacks ids', () {
      expect(nameOnly.matches(withIds), isTrue);
      expect(withIds.matches(nameOnly), isTrue);
    });

    test('rejects different names when ids are unavailable', () {
      expect(nameOnly.matches(const GamepadDeviceKey(name: '8BitDo')), isFalse);
    });

    test('treats a half-populated key as name-only', () {
      const half = GamepadDeviceKey(name: 'Sony DualSense', vendorId: 1356);

      expect(half.matches(withIds), isTrue);
    });
  });

  group('placeholders', () {
    const placeholder = GamepadDeviceKey(name: unknownGamepadName);

    const placeholderWithIds = GamepadDeviceKey(
      name: unknownGamepadName,
      vendorId: 1356,
      productId: 3302,
    );

    test('the unknown name makes a key a placeholder, ids or not', () {
      expect(placeholder.isPlaceholder, isTrue);
      expect(placeholderWithIds.isPlaceholder, isTrue);
    });

    test('a named key is never a placeholder', () {
      expect(withIds.isPlaceholder, isFalse);
      expect(nameOnly.isPlaceholder, isFalse);
    });

    test('a name improves on a placeholder that already had ids', () {
      expect(withIds.improvesOn(placeholderWithIds), isTrue);
    });

    test('a placeholder improves on nothing', () {
      expect(placeholderWithIds.improvesOn(nameOnly), isFalse);
      expect(placeholder.improvesOn(withIds), isFalse);
    });
  });

  group('improvesOn', () {
    test('ids improve on a name-only key', () {
      expect(withIds.improvesOn(nameOnly), isTrue);
    });

    test('dropping ids is not an improvement', () {
      expect(nameOnly.improvesOn(withIds), isFalse);
    });
  });

  group('equality', () {
    test('is strict over all three fields', () {
      expect(withIds == nameOnly, isFalse);
      expect(
        withIds ==
            const GamepadDeviceKey(
              name: 'Sony DualSense',
              vendorId: 1356,
              productId: 3302,
            ),
        isTrue,
      );
    });

    test('equal keys share a hash code', () {
      const same = GamepadDeviceKey(
        name: 'Sony DualSense',
        vendorId: 1356,
        productId: 3302,
      );

      expect(withIds.hashCode, same.hashCode);
    });
  });

  group('json', () {
    test('round-trips a full key', () {
      expect(GamepadDeviceKey.tryFromJson(withIds.toJson()), withIds);
    });

    test('round-trips a name-only key', () {
      expect(GamepadDeviceKey.tryFromJson(nameOnly.toJson()), nameOnly);
    });

    test('omits absent ids', () {
      expect(nameOnly.toJson(), {'name': 'Sony DualSense'});
    });

    test('returns null for anything that is not a named key', () {
      expect(GamepadDeviceKey.tryFromJson('nonsense'), isNull);
      expect(GamepadDeviceKey.tryFromJson(null), isNull);
      expect(GamepadDeviceKey.tryFromJson({'vendorId': 1356}), isNull);
      expect(GamepadDeviceKey.tryFromJson({'name': 5}), isNull);
    });

    test('drops ids that are not numbers', () {
      expect(
        GamepadDeviceKey.tryFromJson({'name': 'Pad', 'vendorId': 'x'}),
        const GamepadDeviceKey(name: 'Pad'),
      );
    });

    test('accepts ids stored as doubles', () {
      expect(
        GamepadDeviceKey.tryFromJson({
          'name': 'Pad',
          'vendorId': 1356.0,
          'productId': 3302.0,
        }),
        const GamepadDeviceKey(name: 'Pad', vendorId: 1356, productId: 3302),
      );
    });
  });
}
