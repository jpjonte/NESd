import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';

void migrateGamepadSlots(Map<String, dynamic> json) {
  final slots = <String, int>{};
  final names = <int, String>{};

  for (final input in _gamepadInputs(json['bindings'])) {
    final id = input.remove('gamepadId');
    final name = input.remove('gamepadName');

    if (id is! String) {
      continue;
    }

    final slot = slots.putIfAbsent(id, () => slots.length);

    input['slot'] = slot;

    if (name is String && name != unknownGamepadName) {
      names[slot] = name;
    }
  }

  if (names.isEmpty) {
    return;
  }

  json['gamepadSlots'] = {
    for (final MapEntry(key: slot, value: name) in names.entries)
      slot.toString(): {'name': name},
  };
}

/// The gamepad inputs of both stored shapes: the current list of bindings,
/// and the legacy map of action code to a single input or a list of them.
Iterable<Map<dynamic, dynamic>> _gamepadInputs(Object? bindings) =>
    switch (bindings) {
      final List<dynamic> list => list.expand(
        (binding) => _gamepadInputsOf(binding is Map ? binding['input'] : null),
      ),
      final Map<dynamic, dynamic> map => map.values.expand(_gamepadInputsOf),
      _ => const [],
    };

Iterable<Map<dynamic, dynamic>> _gamepadInputsOf(Object? input) =>
    switch (input) {
      final List<dynamic> list => list.expand(_gamepadInputsOf),
      final Map<dynamic, dynamic> map when map['type'] == 'gamepad' => [map],
      _ => const [],
    };
