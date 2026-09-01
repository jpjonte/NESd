import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';

@immutable
class GamepadSlotAssignment {
  const GamepadSlotAssignment({
    required this.slot,
    required this.gamepadId,
    required this.key,
  });

  final int slot;
  final String gamepadId;
  final GamepadDeviceKey key;
}

class GamepadSlotRegistry extends ChangeNotifier {
  GamepadSlotRegistry({
    required this.directory,
    Map<int, GamepadDeviceKey> remembered = const {},
  }) : _remembered = {...remembered};

  final GamepadDeviceDirectory directory;

  final Map<int, GamepadDeviceKey> _remembered;
  final Map<int, String> _live = {};
  final Map<String, GamepadDeviceKey> _keys = {};

  bool _disposed = false;

  Map<int, GamepadDeviceKey> get remembered => Map.unmodifiable(_remembered);

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }

  String? gamepadIdFor(int slot) => _live[slot];

  int? slotOf(String gamepadId) {
    for (final MapEntry(key: slot, value: id) in _live.entries) {
      if (id == gamepadId) {
        return slot;
      }
    }

    return null;
  }

  List<GamepadSlotAssignment> get assignments {
    final result = [
      for (final MapEntry(key: slot, value: id) in _live.entries)
        GamepadSlotAssignment(
          slot: slot,
          gamepadId: id,
          key: _keys[id] ?? const GamepadDeviceKey(name: unknownGamepadName),
        ),
    ]..sort((a, b) => a.slot.compareTo(b.slot));

    return result;
  }

  Future<void> seed() async {
    final known = _live.values.toSet();
    final devices = await directory.refresh();

    if (devices == null || _disposed) {
      return;
    }

    final observed = _live.values.toSet().difference(known);

    releaseAllExcept({...devices.keys, ...observed});

    for (final MapEntry(key: id, value: key) in devices.entries) {
      observe(id, key);
    }
  }

  int observe(String gamepadId, GamepadDeviceKey key) {
    final existing = slotOf(gamepadId);

    if (existing != null) {
      _upgradeKey(gamepadId, existing, key);

      return existing;
    }

    _keys[gamepadId] = key;

    final slot = _slotFor(key);

    _live[slot] = gamepadId;
    _remember(slot, key);

    unawaited(_reconcile(gamepadId));

    notifyListeners();

    return slot;
  }

  void assign(int slot, String gamepadId) {
    final from = slotOf(gamepadId);

    if (from == slot) {
      return;
    }

    if (from == null) {
      return;
    }

    final displaced = _live[slot];

    _live[slot] = gamepadId;
    _live.remove(from);

    if (displaced != null) {
      _live[from] = displaced;
    }

    _reRemember();
    _forgetStaleRemembered(slot, gamepadId);

    notifyListeners();
  }

  void releaseAllExcept(Set<String> gamepadIds) {
    final gone = [
      for (final MapEntry(key: slot, value: id) in _live.entries)
        if (!gamepadIds.contains(id)) slot,
    ];

    if (gone.isEmpty) {
      return;
    }

    for (final slot in gone) {
      _keys.remove(_live.remove(slot));
    }

    notifyListeners();
  }

  int _slotFor(GamepadDeviceKey key) {
    final candidates =
        _remembered.entries
            .where((e) => !_live.containsKey(e.key) && e.value.matches(key))
            .map((e) => e.key)
            .toList()
          ..sort();

    if (candidates.isNotEmpty) {
      return candidates.first;
    }

    var slot = 0;

    while (_live.containsKey(slot)) {
      slot++;
    }

    return slot;
  }

  void _remember(int slot, GamepadDeviceKey key) {
    if (key.isPlaceholder) {
      return;
    }

    _remembered[slot] = key;
  }

  void _upgradeKey(String gamepadId, int slot, GamepadDeviceKey key) {
    final current = _keys[gamepadId];

    if (current == null || !key.improvesOn(current)) {
      return;
    }

    _keys[gamepadId] = key;
    _remember(slot, key);

    notifyListeners();
  }

  void _reRemember() {
    for (final MapEntry(key: slot, value: id) in _live.entries) {
      final key = _keys[id];

      if (key != null) {
        _remember(slot, key);
      }
    }
  }

  void _forgetStaleRemembered(int slot, String gamepadId) {
    final key = _keys[gamepadId];

    if (key == null) {
      return;
    }

    _remembered.removeWhere((s, k) => s != slot && k.matches(key));
  }

  Future<void> _reconcile(String gamepadId) async {
    final known = _live.values.toSet();
    final devices = await directory.refresh();

    if (devices == null || _disposed || !_keys.containsKey(gamepadId)) {
      return;
    }

    final observed = _live.values.toSet().difference(known);

    releaseAllExcept({...devices.keys, gamepadId, ...observed});

    final key = _keys[gamepadId];
    final current = slotOf(gamepadId);

    if (key == null || current == null) {
      return;
    }

    final preferred = _slotFor(key);

    if (preferred < current) {
      _live
        ..remove(current)
        ..[preferred] = gamepadId;

      _remember(preferred, key);

      notifyListeners();
    }
  }
}
