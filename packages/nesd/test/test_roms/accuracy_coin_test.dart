import 'package:flutter_test/flutter_test.dart';

import 'accuracy_coin_robot.dart';

const _base = '../../roms/test';

const _knownFailures = <String, int>{'AccuracyCoin/AccuracyCoin.nes': 12};

final _rom = _knownFailures.keys.single;

const _failingTests = <String, int>{
  'APU Registers and DMA tests / DMC DMA Bus Conflicts': 2,
  'APU Registers and DMA tests / Explicit DMA Abort': 2,
  'APU Registers and DMA tests / Implicit DMA Abort': 2,
  'APU Tests / APU Register Activation': 4,
  'Sprite Evaluation / \$2002 flag timing': 1,
  'Sprite Evaluation / OAM Corruption': 2,
  'PPU Misc. / \$2007 Stress Test': 2,
  'Advanced Background Evaluation / Stale BG Shift Registers': 3,
  'Advanced Background Evaluation / BG Serial In': 2,
  'Advanced Background Evaluation / ALE + Read': 2,
  'Advanced Background Evaluation / Hybrid Addresses': 2,
  'Advanced Sprite Evaluation / Stale Sprite Shift Regs': 2,
};

void main() {
  final robot = AccuracyCoinRobot('$_base/$_rom');

  late final Map<String, AccuracyCoinResult> results;

  setUpAll(() {
    results = {for (final result in robot.runAll()) result.test.id: result};
  });

  test('known failures are AccuracyCoin tests', () {
    final ids = {for (final test in robot.scoredTests) test.id};

    expect(_failingTests.keys.where((id) => !ids.contains(id)), isEmpty);
    expect(_failingTests, hasLength(_knownFailures[_rom]));
  });

  group('passing', () {
    for (final coinTest in robot.scoredTests) {
      if (_failingTests.containsKey(coinTest.id)) {
        continue;
      }

      test(coinTest.id, () {
        final result = results[coinTest.id]!;

        expect(result.passed, isTrue, reason: result.toString());
      });
    }
  });

  group('known failures', () {
    for (final entry in _failingTests.entries) {
      test(entry.key, () {
        final result = results[entry.key]!;

        expect(
          result.status,
          equals(AccuracyCoinStatus.failed),
          reason: result.toString(),
        );

        expect(result.code, equals(entry.value), reason: result.toString());
      });
    }
  });
}
