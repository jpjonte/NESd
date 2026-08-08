import 'package:collection/collection.dart';

enum EmulatorTool {
  tileViewer('Tile Viewer', contentWidth: _standardToolWidth, minHeight: 480),
  cartridgeInfo(
    'Cartridge Info',
    contentWidth: _standardToolWidth,
    minHeight: 372,
  ),
  apuDebug('APU Debug', contentWidth: _standardToolWidth, minHeight: 408),
  debugger('Debugger', contentWidth: _standardToolWidth, minHeight: 400),
  executionLog(
    'Execution Log',
    contentWidth: executionLogWidth,
    minHeight: 400,
  );

  const EmulatorTool(
    this.title, {
    required this.contentWidth,
    required this.minHeight,
  });

  final String title;

  final double contentWidth;

  final double minHeight;
}

const _standardToolWidth = 512.0;

const executionLogWidth = 560.0;

const dockedToolColumnWidth = executionLogWidth;

const _minDisplayWidth = 512.0;

const dockedToolsMinWidth = dockedToolColumnWidth + _minDisplayWidth;

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
