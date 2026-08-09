part of '../input_action.dart';

class ToggleTool extends InputAction {
  const ToggleTool({
    required this.tool,
    required super.title,
    required super.code,
  });

  final EmulatorTool tool;
}

const toggleTileViewer = ToggleTool(
  tool: EmulatorTool.tileViewer,
  title: 'Toggle Tile Viewer',
  code: 'tool.tileViewer',
);

const toggleCartridgeInfo = ToggleTool(
  tool: EmulatorTool.cartridgeInfo,
  title: 'Toggle Cartridge Info',
  code: 'tool.cartridgeInfo',
);

const toggleDebugger = ToggleTool(
  tool: EmulatorTool.debugger,
  title: 'Toggle Debugger',
  code: 'tool.debugger',
);

const toggleApuDebug = ToggleTool(
  tool: EmulatorTool.apuDebug,
  title: 'Toggle APU Debug',
  code: 'tool.apuDebug',
);

const toggleExecutionLog = ToggleTool(
  tool: EmulatorTool.executionLog,
  title: 'Toggle Execution Log',
  code: 'tool.executionLog',
);
