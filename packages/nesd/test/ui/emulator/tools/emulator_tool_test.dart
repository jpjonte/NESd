import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';

void main() {
  test('the docked column is as wide as its widest tool', () {
    final widest = EmulatorTool.values
        .map((tool) => tool.contentWidth)
        .reduce(max);

    expect(dockedToolColumnWidth, widest);
  });

  test('every tool declares a usable content size', () {
    for (final tool in EmulatorTool.values) {
      expect(tool.contentWidth, greaterThan(0), reason: '$tool width');
      expect(tool.minHeight, greaterThan(0), reason: '$tool height');
    }
  });

  test('the execution log is the tool the column width comes from', () {
    expect(EmulatorTool.executionLog.contentWidth, executionLogWidth);
  });

  test('only the debugger toolset requires Features.debugger', () {
    const debuggerTools = {
      EmulatorTool.debugger,
      EmulatorTool.apuDebug,
      EmulatorTool.executionLog,
    };

    for (final tool in EmulatorTool.values) {
      expect(
        tool.requiresDebugger,
        debuggerTools.contains(tool),
        reason: '$tool',
      );
    }
  });
}
