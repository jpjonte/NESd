import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_data.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apu_debug_controller.g.dart';

@riverpod
Raw<ApuDebugController?> apuDebugController(Ref ref) {
  final nes = ref.watch(nesStateProvider);

  if (nes == null) {
    return null;
  }

  final controller = ApuDebugController(nes);

  ref.onDispose(controller.dispose);

  return controller;
}

class ApuDebugController extends ChangeNotifier {
  ApuDebugController(this._nes) {
    _subscription = _nes.events.listen(_handleEvent);

    _nes.setApuDebugEnabled(true);
  }

  final RemoteNes _nes;

  ApuDebugData? data;

  late final StreamSubscription<NesIsolateEvent> _subscription;

  @override
  void dispose() {
    _nes.setApuDebugEnabled(false);

    unawaited(_subscription.cancel());

    super.dispose();
  }

  void _handleEvent(NesIsolateEvent event) {
    if (event is! ApuDebugEvent) {
      return;
    }

    data = ApuDebugData.fromEvent(event);

    notifyListeners();
  }
}
