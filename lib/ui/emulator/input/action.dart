import 'package:nesd/nes/bus.dart';
import 'package:nesd/ui/emulator/input/action/all_actions.dart';

part 'action/controller_press.dart';
part 'action/load_state.dart';
part 'action/save_state.dart';
part 'action/state.dart';
part 'action/ui.dart';

sealed class NesAction {
  const NesAction({
    required this.title,
    required this.code,
  });

  factory NesAction.fromCode(String code) {
    return allActions.firstWhere((action) => action.code == code);
  }

  static String toJson(NesAction action) => action.code;

  final String title;
  final String code;

  @override
  String toString() => title;
}
