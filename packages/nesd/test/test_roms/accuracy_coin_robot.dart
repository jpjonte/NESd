import 'package:flutter/foundation.dart';
import 'package:nesd/nes/bus.dart';

import 'rom_robot.dart';

@immutable
class AccuracyCoinTest {
  const AccuracyCoinTest({
    required this.suite,
    required this.name,
    required this.resultAddress,
  });

  final String suite;
  final String name;
  final int resultAddress;

  bool get isDraw => resultAddress >> 8 == 3;

  String get id => '$suite / $name';
}

enum AccuracyCoinStatus { notRun, passed, failed, running, skipped }

@immutable
class AccuracyCoinResult {
  const AccuracyCoinResult({required this.test, required this.value});

  final AccuracyCoinTest test;
  final int value;

  AccuracyCoinStatus get status {
    if (value == 0xff) {
      return AccuracyCoinStatus.skipped;
    }

    return switch (value & 3) {
      1 => AccuracyCoinStatus.passed,
      2 => AccuracyCoinStatus.failed,
      3 => AccuracyCoinStatus.running,
      _ => AccuracyCoinStatus.notRun,
    };
  }

  bool get passed => status == AccuracyCoinStatus.passed;

  int get code => value >> 2;

  String get _codeDigit => code.toRadixString(36).toUpperCase();

  @override
  String toString() => switch (status) {
    AccuracyCoinStatus.passed when code != 0 => 'PASS $_codeDigit',
    AccuracyCoinStatus.passed => 'PASS',
    AccuracyCoinStatus.failed => 'FAIL $_codeDigit',
    AccuracyCoinStatus.running => 'HUNG',
    AccuracyCoinStatus.skipped => 'SKIP',
    AccuracyCoinStatus.notRun => 'NOT RUN',
  };
}

class AccuracyCoinRobot {
  static const _tableTable = 0x8100;
  static const _menuCursorYPos = 0x16;
  static const _runningAllTests = 0x35;
  static const _cursorAtTop = 0xff;
  static const _skipMarker = 0xff;
  static const _runningMarker = 3;

  AccuracyCoinRobot(this.path) : tests = _parseTests(RomRobot(path));

  final String path;
  final List<AccuracyCoinTest> tests;

  List<AccuracyCoinTest> get scoredTests => [
    for (final test in tests)
      if (!test.isDraw) test,
  ];

  List<AccuracyCoinResult> runAll({int maxFramesPerTest = 1800}) {
    final hung = <AccuracyCoinTest>{};

    while (true) {
      final robot = RomRobot(path);
      final stuck = _runOnce(robot, hung, maxFramesPerTest);

      if (stuck != null) {
        hung.add(stuck);

        continue;
      }

      return [
        for (final test in scoredTests)
          AccuracyCoinResult(
            test: test,
            value: hung.contains(test)
                ? _runningMarker
                : _peek(robot, test.resultAddress),
          ),
      ];
    }
  }

  /// Runs a single test and returns the console it ran on, so the RAM the
  /// test left behind can be inspected.
  RomRobot runOnly(String id) {
    final robot = RomRobot(path);

    final skipped = {
      for (final test in scoredTests)
        if (test.id != id) test,
    };

    _runOnce(robot, skipped, 1800);

    return robot;
  }

  AccuracyCoinTest? _runOnce(
    RomRobot robot,
    Set<AccuracyCoinTest> skipped,
    int maxFramesPerTest,
  ) {
    _waitForMenu(robot);

    for (final test in skipped) {
      robot.nes.bus.cpuWrite(test.resultAddress, _skipMarker);
    }

    final pending = [
      for (final test in scoredTests)
        if (!skipped.contains(test)) test,
    ];

    for (final test in pending) {
      robot.nes.bus.cpuWrite(test.resultAddress, 0);
    }

    robot.buttonDown(0, NesButton.start);

    _runUntil(robot, () => _peek(robot, _runningAllTests) != 0, 120);

    robot.buttonUp(0, NesButton.start);

    for (final test in pending) {
      final finished = _runUntil(
        robot,
        () => _peek(robot, test.resultAddress) != 0,
        maxFramesPerTest,
      );

      if (!finished) {
        return test;
      }
    }

    _runUntil(robot, () => _peek(robot, _runningAllTests) == 0, 120);

    return null;
  }

  void _waitForMenu(RomRobot robot) {
    final ready = _runUntil(
      robot,
      () => _peek(robot, _menuCursorYPos) == _cursorAtTop,
      600,
    );

    if (!ready) {
      throw StateError('AccuracyCoin never reached its menu');
    }

    robot.runFrames(30);
  }

  bool _runUntil(RomRobot robot, bool Function() done, int maxFrames) {
    for (var frame = 0; frame < maxFrames; frame++) {
      if (done()) {
        return true;
      }

      try {
        robot.runFrames(1);
      } on Object {
        return done();
      }
    }

    return done();
  }

  static int _peek(RomRobot robot, int address) =>
      robot.nes.bus.cpuRead(address, disableSideEffects: true);

  static List<AccuracyCoinTest> _parseTests(RomRobot robot) {
    int word(int address) =>
        _peek(robot, address) | _peek(robot, address + 1) << 8;

    final firstSuite = word(_tableTable);

    final tests = <AccuracyCoinTest>[];

    for (var entry = _tableTable; entry < firstSuite; entry += 2) {
      var address = word(entry);

      String text() {
        final buffer = StringBuffer();

        while (_peek(robot, address) != 0xff) {
          buffer.writeCharCode(_peek(robot, address++));
        }

        address++;

        return buffer.toString();
      }

      final suite = text();

      while (_peek(robot, address) != 0xff) {
        final name = text();

        tests.add(
          AccuracyCoinTest(
            suite: suite,
            name: name.replaceAll(RegExp(r'\s+'), ' '),
            resultAddress: word(address),
          ),
        );

        address += 4;
      }
    }

    return tests;
  }
}
