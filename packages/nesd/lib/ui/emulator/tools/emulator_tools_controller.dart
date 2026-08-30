import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:nesd/features.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emulator_tools_controller.g.dart';

@visibleForTesting
bool isToolAvailable(EmulatorTool tool, {required bool debuggerEnabled}) =>
    debuggerEnabled || !tool.requiresDebugger;

@visibleForTesting
Set<EmulatorTool> availableTools(
  Set<EmulatorTool> tools, {
  required bool debuggerEnabled,
}) => tools
    .where((tool) => isToolAvailable(tool, debuggerEnabled: debuggerEnabled))
    .toSet();

Set<EmulatorTool> navigableTools(Set<EmulatorTool> tools) =>
    tools.where((tool) => !tool.pointerOnly).toSet();

@riverpod
class EmulatorToolsController extends _$EmulatorToolsController {
  @override
  Set<EmulatorTool> build() => availableTools(
    ref.watch(settingsControllerProvider.select((s) => s.openTools)),
    debuggerEnabled: Features.debugger,
  );

  bool isOpen(EmulatorTool tool) => state.contains(tool);

  void open(EmulatorTool tool) {
    if (!isToolAvailable(tool, debuggerEnabled: Features.debugger)) {
      return;
    }

    _write({...state, tool});
  }

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
