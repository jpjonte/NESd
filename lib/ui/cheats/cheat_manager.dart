import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cheat_manager.g.dart';

@riverpod
class CheatManager extends _$CheatManager {
  @override
  List<Cheat> build(RomInfo romInfo) {
    final settings = ref.watch(settingsControllerProvider);
    final key = _getCheatsKey(romInfo);

    return settings.cheats[key] ?? const [];
  }

  String _getCheatsKey(RomInfo romInfo) =>
      romInfo.romHash ?? romInfo.hash ?? romInfo.file.name;

  void _updateSettings(List<Cheat> newCheats) {
    final key = _getCheatsKey(romInfo);
    ref.read(settingsControllerProvider.notifier).setCheats(key, newCheats);

    final nes = ref.read(nesStateProvider);

    if (nes != null && nes.bus.cartridge.romInfo == romInfo) {
      nes.cheats = newCheats;
    }
  }

  Future<void> addCheat(Cheat cheat) async {
    final newCheats = [...state, cheat];

    _updateSettings(newCheats);
  }

  Future<void> removeCheat(String id) async {
    final newCheats = state.where((c) => c.id != id).toList();

    _updateSettings(newCheats);
  }

  Future<void> updateCheat(Cheat updatedCheat) async {
    final newCheats = [
      for (final cheat in state)
        if (cheat.id == updatedCheat.id) updatedCheat else cheat,
    ];

    _updateSettings(newCheats);
  }

  Future<void> toggleCheat(String id) async {
    final newCheats = [
      for (final cheat in state)
        if (cheat.id == id) cheat.copyWith(enabled: !cheat.enabled) else cheat,
    ];

    _updateSettings(newCheats);
  }

  Future<void> clearAllCheats() async => _updateSettings([]);
}
