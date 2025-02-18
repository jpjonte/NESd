import 'dart:async';

import 'package:nesd/nes/event/nes_event.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_bus.g.dart';

@riverpod
EventBus eventBus(Ref ref) {
  return EventBus();
}

class EventBus {
  EventBus() : _streamController = StreamController.broadcast(sync: true);

  final StreamController<NesEvent> _streamController;

  Stream<NesEvent> get stream => _streamController.stream;

  void add(NesEvent event) {
    _streamController.add(event);
  }
}
