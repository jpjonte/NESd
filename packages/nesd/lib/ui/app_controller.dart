import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_controller.g.dart';

typedef QuitApp = void Function();

@riverpod
QuitApp quitApp(Ref ref) => quit;

@riverpod
AppController appController(Ref ref) {
  final controller = AppController(
    nesController: ref.watch(nesControllerProvider),
    quitApp: ref.watch(quitAppProvider),
  );

  ref.onDispose(controller.dispose);

  final activeSubscription = ref.listen(
    emulatorActiveProvider,
    (_, active) => controller.suspendWhenHidden = active,
    fireImmediately: true,
  );

  ref.onDispose(activeSubscription.close);

  return controller;
}

class AppController {
  AppController({
    required this.nesController,
    required this.quitApp,
    this.exitSaveTimeout = const Duration(seconds: 3),
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _suspended,
      onInactive: _suspended,
      onShow: _suspended,
      onResume: _resumed,
    );
  }

  final NesController nesController;

  final QuitApp quitApp;

  final Duration exitSaveTimeout;

  bool suspendWhenHidden = true;

  late final AppLifecycleListener _lifecycleListener;

  Future<void> quit() async {
    await _saveAndStop();

    quitApp();
  }

  void dispose() => _lifecycleListener.dispose();

  Future<void> _saveAndStop() async {
    try {
      await nesController.stop().timeout(exitSaveTimeout);
    } on TimeoutException {
      log.app.warning('Timed out saving on the way out');
    }
  }

  void _suspended() {
    if (suspendWhenHidden) {
      nesController.suspend();
    }
  }

  void _resumed() {
    if (suspendWhenHidden) {
      nesController.applyRunState();
    }
  }
}
