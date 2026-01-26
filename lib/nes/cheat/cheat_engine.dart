import 'package:collection/collection.dart';
import 'package:nesd/nes/cheat/cheat.dart';

/// CheatEngine applies active cheat codes to the NES memory during execution
class CheatEngine {
  final List<Cheat> _cheats = [];
  final Map<int, Cheat> _cheatsMap = {};

  List<Cheat> get cheats => List.unmodifiable(_cheats);

  void addCheat(Cheat cheat) {
    _cheats.add(cheat);
    _updateCheatsMap();
  }

  void removeCheat(String id) {
    _cheats.removeWhere((cheat) => cheat.id == id);
    _updateCheatsMap();
  }

  void removeAllCheats() {
    _cheats.clear();
    _cheatsMap.clear();
  }

  void updateCheat(Cheat updatedCheat) {
    final index = _cheats.indexWhere((c) => c.id == updatedCheat.id);

    if (index != -1) {
      _cheats[index] = updatedCheat;
      _updateCheatsMap();
    }
  }

  void enableCheat(String id, {required bool enabled}) {
    final cheat = _cheats.firstWhereOrNull((c) => c.id == id);

    if (cheat == null) {
      return;
    }

    final index = _cheats.indexOf(cheat);

    _cheats[index] = _cheats[index].copyWith(enabled: enabled);
    _updateCheatsMap();
  }

  void _updateCheatsMap() {
    _cheatsMap.clear();

    for (final cheat in _cheats) {
      if (cheat.enabled) {
        _cheatsMap[cheat.address] = cheat;
      }
    }
  }

  /// Apply cheats to memory access
  /// Cheats with compare values are only applied if the current value matches
  int apply(int address, int value) {
    final cheat = _cheatsMap[address];

    if (cheat == null) {
      return value;
    }

    if (cheat.compareValue != null) {
      // For cheats with compare values, only apply if current value matches
      if (value == cheat.compareValue) {
        return cheat.value;
      }
    } else {
      // For cheats without compare values, always apply
      return cheat.value;
    }

    return value;
  }
}
