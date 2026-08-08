import 'package:collection/collection.dart';

enum EmulatorTool {
  tileViewer('Tile Viewer'),
  cartridgeInfo('Cartridge Info'),
  apuDebug('APU Debug'),
  debugger('Debugger'),
  executionLog('Execution Log');

  const EmulatorTool(this.title);

  final String title;
}

const dockedToolsMinWidth = 1024.0;

Set<EmulatorTool> openToolsFromJson(dynamic json) {
  if (json is! List) {
    return const {};
  }

  return {
    for (final name in json)
      if (EmulatorTool.values.firstWhereOrNull((t) => t.name == name)
          case final tool?)
        tool,
  };
}
