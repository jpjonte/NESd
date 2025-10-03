import 'package:collection/collection.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';

part 'action/controller_press.dart';
part 'action/load_state.dart';
part 'action/save_state.dart';
part 'action/state.dart';
part 'action/ui.dart';

sealed class InputAction {
  const InputAction({
    required this.title,
    required this.code,
    this.toggleable = false,
  });

  static InputAction? fromCode(String? code) {
    if (code == null) {
      return null;
    }

    return allActions.firstWhereOrNull((action) => action.code == code);
  }

  static String? toJson(InputAction? action) => action?.code;

  final String title;
  final String code;
  final bool toggleable;

  @override
  String toString() => title;
}
