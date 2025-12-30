import 'dart:convert';

import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/cheat/game_genie_decoder.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cheat_manager.g.dart';

@riverpod
class CheatManager extends _$CheatManager {
  @override
  List<Cheat> build() => [];

  Future<void> loadCheats(RomInfo romInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCheatsKey(romInfo);
    final json = prefs.getString(key);

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final cheatsList = data['cheats'] as List<dynamic>?;
        if (cheatsList != null) {
          state = cheatsList
              .map((c) => Cheat.fromJson(c as Map<String, dynamic>))
              .toList();

          // Sync cheats to active NES instance
          _syncCheatsToNes();
        }
      } on Exception {
        // Invalid JSON, start fresh
        state = [];
      }
    }
  }

  Future<void> _saveCheats(RomInfo romInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCheatsKey(romInfo);
    final data = {'cheats': state.map((c) => c.toJson()).toList()};
    await prefs.setString(key, jsonEncode(data));
  }

  String _getCheatsKey(RomInfo romInfo) {
    final hash = romInfo.romHash ?? romInfo.hash ?? romInfo.file.name;
    return 'cheats_$hash';
  }

  void _syncCheatsToNes() {
    final nes = ref.read(nesStateProvider);
    if (nes != null) {
      nes.bus.cheatEngine.removeAllCheats();
      for (final cheat in state) {
        nes.bus.cheatEngine.addCheat(cheat);
      }
    }
  }

  Future<void> addCheat(Cheat cheat, RomInfo romInfo) async {
    state = [...state, cheat];
    await _saveCheats(romInfo);

    // Add to active NES instance
    final nes = ref.read(nesStateProvider);
    nes?.bus.cheatEngine.addCheat(cheat);
  }

  Future<void> removeCheat(String id, RomInfo romInfo) async {
    state = state.where((c) => c.id != id).toList();
    await _saveCheats(romInfo);

    // Remove from active NES instance
    final nes = ref.read(nesStateProvider);
    nes?.bus.cheatEngine.removeCheat(id);
  }

  Future<void> updateCheat(Cheat updatedCheat, RomInfo romInfo) async {
    state = [
      for (final cheat in state)
        if (cheat.id == updatedCheat.id) updatedCheat else cheat,
    ];

    await _saveCheats(romInfo);

    // Update in active NES instance
    final nes = ref.read(nesStateProvider);
    nes?.bus.cheatEngine.updateCheat(updatedCheat);
  }

  Future<void> toggleCheat(String id, RomInfo romInfo) async {
    state = [
      for (final cheat in state)
        if (cheat.id == id) cheat.copyWith(enabled: !cheat.enabled) else cheat,
    ];

    await _saveCheats(romInfo);

    // Toggle in active NES instance
    final nes = ref.read(nesStateProvider);
    final cheat = state.firstWhere((c) => c.id == id);
    nes?.bus.cheatEngine.enableCheat(id, enabled: cheat.enabled);
  }

  Future<void> clearAllCheats(RomInfo romInfo) async {
    state = [];
    await _saveCheats(romInfo);

    // Clear from active NES instance
    final nes = ref.read(nesStateProvider);
    nes?.bus.cheatEngine.removeAllCheats();
  }

  Cheat? decodeGameGenie(String code, {String? name}) =>
      GameGenieDecoder.decode(code, name: name);

  bool isValidGameGenieCode(String code) => GameGenieDecoder.isValidCode(code);
}
