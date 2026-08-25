@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/util/wait.dart';

void main() {
  test('wait reaches the requested duration', () async {
    final stopwatch = Stopwatch()..start();

    await wait(const Duration(milliseconds: 6));

    expect(stopwatch.elapsedMicroseconds, greaterThanOrEqualTo(6000));
  });

  test('a zero wait still yields to the event loop', () async {
    var ranMacrotask = false;

    // A queued macrotask must get a chance to run across wait(0).
    Future<void>.delayed(Duration.zero, () => ranMacrotask = true);

    await wait(Duration.zero);
    await wait(Duration.zero);

    expect(ranMacrotask, isTrue);
  });

  test('back-to-back short waits stay precise', () async {
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < 10; i++) {
      await wait(const Duration(milliseconds: 2));
    }

    final elapsed = stopwatch.elapsedMicroseconds;

    expect(elapsed, greaterThanOrEqualTo(20000));
    // Ten chained setTimeout(2)s cost >=32ms (the 4 ms clamp applies
    // from the 5th nesting level); the macrotask refinement keeps the
    // total close to 20ms.
    expect(elapsed, lessThan(36000));
  });
}
