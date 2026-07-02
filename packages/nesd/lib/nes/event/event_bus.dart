import 'dart:async';

import 'package:nesd/nes/event/nes_event.dart';

class EventBus {
  EventBus() : _streamController = StreamController.broadcast();

  final StreamController<NesEvent> _streamController;

  Stream<NesEvent> get stream => _streamController.stream;

  void add(NesEvent event) {
    _streamController.add(event);
  }
}
