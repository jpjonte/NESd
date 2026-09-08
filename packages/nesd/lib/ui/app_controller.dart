import 'package:flutter/widgets.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_controller.g.dart';

@riverpod
AppController appController(Ref ref) {
  final controller = AppController(
    nesController: ref.watch(nesControllerProvider),
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
  AppController({required this.nesController}) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _suspended,
      onInactive: _suspended,
      onShow: _suspended,
      onResume: _resumed,
    );
  }

  final NesController nesController;

  bool suspendWhenHidden = true;

  late final AppLifecycleListener _lifecycleListener;

  void dispose() => _lifecycleListener.dispose();

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
