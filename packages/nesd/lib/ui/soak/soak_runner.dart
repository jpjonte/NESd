import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/soak/soak_config.dart';
import 'package:nesd/soak/soak_stats.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/util/wait.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'soak_runner.g.dart';

@riverpod
SoakConfig? soakConfig(Ref ref) => null;

@Riverpod(keepAlive: true)
SoakRunner? soakRunner(Ref ref) {
  final config = ref.watch(soakConfigProvider);

  if (config == null) {
    return null;
  }

  final runner = SoakRunner(
    config: config,
    controller: ref.watch(nesControllerProvider),
    router: ref.read(routerProvider),
  );

  unawaited(runner.run());

  return runner;
}

class SoakRunner {
  SoakRunner({
    required this.config,
    required this.controller,
    required this.router,
    Future<void> Function()? waitForFirstFrame,
    this.exitApp = exit,
  }) : _waitForFirstFrame =
           waitForFirstFrame ?? (() => WidgetsBinding.instance.endOfFrame);

  final SoakConfig config;
  final NesController controller;
  final Router router;
  final void Function(int) exitApp;

  final Future<void> Function() _waitForFirstFrame;

  final List<AudioStatsEvent> _samples = [];

  IOSink? _statsSink;
  StreamSubscription<AudioStatsEvent>? _subscription;

  static bool _launchedInProcess = false;

  @visibleForTesting
  static void resetLaunchGuardForTesting() {
    _launchedInProcess = false;
  }

  Future<void> run() async {
    if (_launchedInProcess) {
      return;
    }

    _launchedInProcess = true;

    try {
      await _waitForFirstFrame();

      final Uint8List bytes;

      try {
        bytes = File(config.romPath).readAsBytesSync();
      } on FileSystemException catch (e) {
        _fail('rom unreadable: $e');

        return;
      }

      final loaded = await controller.loadRom(
        FilesystemFile(
          path: config.romPath,
          name: p.basename(config.romPath),
          type: FilesystemFileType.file,
        ),
        data: bytes,
      );

      if (!loaded) {
        _fail('rom load failed');

        return;
      }

      unawaited(router.navigate(const EmulatorRoute()));

      final nes = controller.nes!
        ..rewindEnabled = true
        ..volume = 1.0;

      if (config.pcm) {
        nes.startPcmDump(config.pcmPath);
      }

      _statsSink = File(config.statsPath).openWrite();

      _subscription = nes.events
          .where((event) => event is AudioStatsEvent)
          .cast<AudioStatsEvent>()
          .listen(_handleStats);

      await wait(Duration(seconds: config.seconds));

      await _finish(nes);
    } on Object catch (e) {
      _fail('$e');
    }
  }

  void _handleStats(AudioStatsEvent event) {
    _samples.add(event);
    _statsSink?.writeln(event.logLine);
  }

  Future<void> _finish(RemoteNes nes) async {
    await _subscription?.cancel();

    nes.stopPcmDump();

    await controller.stop();

    await _statsSink?.flush();
    await _statsSink?.close();

    final summary = SoakSummary.fromSamples(
      rom: p.basename(config.romPath),
      seconds: config.seconds,
      samples: _samples,
    );

    // ignore: avoid_print - logcat is the transport for soak results
    print(summary.logLine);

    exitApp(0);
  }

  void _fail(String message) {
    // ignore: avoid_print - logcat is the transport for soak results
    print('NESD_SOAK_FAILED $message');

    exitApp(1);
  }
}
