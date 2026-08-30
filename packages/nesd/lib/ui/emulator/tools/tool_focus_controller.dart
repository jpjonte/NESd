import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_focus_controller.g.dart';

@riverpod
class ToolFocusController extends _$ToolFocusController {
  @override
  bool build() {
    final toolsSubscription = ref.listen(emulatorToolsControllerProvider, (
      _,
      tools,
    ) {
      if (navigableTools(tools).isEmpty) {
        state = false;
      }
    });

    ref.onDispose(toolsSubscription.close);

    final activeSubscription = ref.listen(emulatorActiveProvider, (_, active) {
      if (!active) {
        state = false;
      }
    });

    ref.onDispose(activeSubscription.close);

    return false;
  }

  void enter() {
    if (navigableTools(ref.read(emulatorToolsControllerProvider)).isEmpty) {
      return;
    }

    state = true;
  }

  void exit() => state = false;

  void toggle() {
    if (state) {
      exit();
    } else {
      enter();
    }
  }
}
