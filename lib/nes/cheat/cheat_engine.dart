import 'package:nesd/nes/cheat/cheat.dart';

/// CheatEngine applies active cheat codes to the NES memory during execution
class CheatEngine {
  final List<Cheat> _cheats = [];

  List<Cheat> get cheats => List.unmodifiable(_cheats);

  void addCheat(Cheat cheat) => _cheats.add(cheat);

  void removeCheat(String id) => _cheats.removeWhere((cheat) => cheat.id == id);

  void removeAllCheats() => _cheats.clear();

  void updateCheat(Cheat updatedCheat) {
    final index = _cheats.indexWhere((c) => c.id == updatedCheat.id);

    if (index != -1) {
      _cheats[index] = updatedCheat;
    }
  }

  void enableCheat(String id, {required bool enabled}) {
    final cheat = _cheats.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Cheat not found: $id'),
    );
    final index = _cheats.indexOf(cheat);

    _cheats[index] = cheat.copyWith(enabled: enabled);
  }

  /// Apply cheats to memory access (both read and write operations)
  /// Cheats with compare values are only applied if the current value matches
  int apply(int address, int value) {
    for (final cheat in _cheats) {
      if (!cheat.enabled) {
        continue;
      }

      if (cheat.address == address) {
        if (cheat.compareValue != null) {
          // For cheats with compare values, only apply if current value matches
          if (value == cheat.compareValue) {
            return cheat.value;
          }
        } else {
          // For cheats without compare values, always apply
          return cheat.value;
        }
      }
    }
    return value;
  }

  /// Apply all enabled cheats to memory at the start of each frame
  /// This ensures cheats persist even if the game tries to overwrite them
  void applyFrameCheats(Function(int address, int value) writeMemory) {
    for (final cheat in _cheats) {
      if (cheat.enabled) {
        writeMemory(cheat.address, cheat.value);
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'cheats': _cheats.map((c) => c.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    _cheats.clear();

    final cheatsList = json['cheats'] as List<dynamic>?;

    if (cheatsList != null) {
      _cheats.addAll(
        cheatsList.map((c) => Cheat.fromJson(c as Map<String, dynamic>)),
      );
    }
  }
}
