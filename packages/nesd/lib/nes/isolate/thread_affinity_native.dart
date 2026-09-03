import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/isolate/cpu_policy.dart';

typedef _GetTid = int Function();
typedef _SetAffinity =
    int Function(int pid, int cpuSetSize, Pointer<Uint8> mask);

/// Keeps the emulator's frames on the fast CPU cores on Android.
// ignore: avoid_classes_with_only_static_members
abstract final class ThreadAffinity {
  // bionic's cpu_set_t is 1024 bits
  static const int _cpuSetBytes = 128;

  static bool _initialized = false;
  static bool _enabled = false;
  static int _lastTid = -1;

  static late _GetTid _getTid;
  static late _SetAffinity _setAffinity;
  static late Pointer<Uint8> _mask;

  static void pinCurrentThread() {
    if (!_initialized) {
      _initialize();
    }

    if (!_enabled) {
      return;
    }

    final tid = _getTid();

    if (tid == _lastTid) {
      return;
    }

    if (_setAffinity(0, _cpuSetBytes, _mask) != 0) {
      _enabled = false;

      log.emulator.warning('Pinning the emulator thread failed');

      return;
    }

    _lastTid = tid;
  }

  static void _initialize() {
    _initialized = true;

    if (!Platform.isAndroid) {
      return;
    }

    final policies = readCpuPolicies(
      Directory('/sys/devices/system/cpu/cpufreq'),
    );
    final cores = fastCoresFrom(policies);

    if (cores.isEmpty || cores.any((cpu) => cpu >= _cpuSetBytes * 8)) {
      log.emulator.info(
        'Emulator not pinned: no faster CPU cluster',
        context: {'policies': policies.length, 'cores': cores},
      );

      return;
    }

    try {
      final libc = DynamicLibrary.process();

      _getTid = libc.lookupFunction<Int32 Function(), _GetTid>('gettid');
      _setAffinity = libc
          .lookupFunction<
            Int32 Function(Int32 pid, Size cpuSetSize, Pointer<Uint8> mask),
            _SetAffinity
          >('sched_setaffinity');
      // lookupFunction throws ArgumentError when a symbol is missing
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      log.emulator.warning('Pinning the emulator thread unavailable', error: e);

      return;
    }

    final mask = calloc<Uint8>(_cpuSetBytes);

    for (final cpu in cores) {
      mask[cpu ~/ 8] |= 1 << (cpu % 8);
    }

    _mask = mask;
    _enabled = true;

    log.emulator.info('Emulator pinned to cpus', context: {'cpus': cores});
  }
}
