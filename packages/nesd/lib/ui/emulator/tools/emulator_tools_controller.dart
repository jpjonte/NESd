import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emulator_tools_controller.g.dart';

@riverpod
class EmulatorToolsController extends _$EmulatorToolsController {
  @override
  Set<EmulatorTool> build() =>
      ref.watch(settingsControllerProvider.select((s) => s.openTools));

  bool isOpen(EmulatorTool tool) => state.contains(tool);

  void open(EmulatorTool tool) => _write({...state, tool});

  void close(EmulatorTool tool) => _write({...state}..remove(tool));

  void toggle(EmulatorTool tool) {
    if (isOpen(tool)) {
      close(tool);
    } else {
      open(tool);
    }
  }

  // forwards to SettingsController.openTools, not a property of this class
  // ignore: use_setters_to_change_properties
  void _write(Set<EmulatorTool> tools) =>
      ref.read(settingsControllerProvider.notifier).openTools = tools;
}
