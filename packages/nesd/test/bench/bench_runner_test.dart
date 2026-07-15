import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/bench/bench_runner.dart';

void main() {
  test('runBench measures frames and produces a parseable log line', () {
    // ROM committed for the golden harness (path relative to packages/nesd,
    // where tests run).
    const romPath = '../../roms/test/scanline/scanline.nes';

    if (!File(romPath).existsSync()) {
      fail('golden ROM missing: $romPath (run from packages/nesd)');
    }

    final result = runBench(romPath: romPath, frames: 30, warmupFrames: 5);

    expect(result.frames, 30);
    expect(result.medianUs, greaterThan(0));
    expect(result.p90Us, greaterThanOrEqualTo(result.medianUs));
    expect(result.flatoutFps, greaterThan(0));
    expect(
      result.logLine,
      matches(
        r'^NESD_BENCH rom=scanline\.nes frames=30 median_us=\d+ '
        r'p90_us=\d+ flatout_fps=\d+(\.\d+)?$',
      ),
    );
  });
}
