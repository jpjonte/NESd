import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';

void main() {
  test('prints one wire line per 60 captures with accumulated stages', () {
    final profiler = RewindProfiler();
    final lines = <String>[];

    runZoned(
      () {
        for (var i = 0; i < 60; i++) {
          profiler
            ..addCapture(10)
            ..addSerialize(20)
            ..addDiff(30)
            ..addCompress(40);
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );

    expect(lines, hasLength(1));
    // 60 captures but 59 stage cycles: _print() fires inside the 60th
    // addCapture, BEFORE that iteration's addSerialize/addDiff/
    // addCompress run — mirroring production, where stages trail their
    // capture via the deferred microtask. 59*20/59*30/59*40.
    expect(
      lines.single,
      'NESD_REWIND_PROF frames=60 cap_us=600 ser_us=1180 '
      'diff_us=1770 comp_us=2360',
    );
  });

  test('window resets after printing', () {
    final profiler = RewindProfiler();
    final lines = <String>[];

    runZoned(
      () {
        for (var i = 0; i < 120; i++) {
          profiler.addCapture(1);
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );

    expect(lines, hasLength(2));
    expect(lines.last, startsWith('NESD_REWIND_PROF frames=60 cap_us=60 '));
  });

  test('maybeRewindProfiler is null without the dart-define', () {
    // The test binary is built without NESD_REWIND_PROF.
    expect(maybeRewindProfiler(), isNull);
  });
}
