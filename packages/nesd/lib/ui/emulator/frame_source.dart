import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

class FrameHandle {
  const FrameHandle({
    required this.bytes,
    required this.width,
    required this.height,
    required this.pointerAddress,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int pointerAddress;
}

abstract class FrameSource extends ChangeNotifier {
  FrameHandle? takeFrame();

  void releaseFrame(FrameHandle handle);
}

/// [FrameSource] backed by frames delivered from the emulator isolate as
/// [FrameEvent]s. Frame memory lives in the worker's native heap; ownership
/// transfers via [ReleaseFrameCommand] round trips through [sendCommand].
class RemoteFrameSource extends FrameSource {
  RemoteFrameSource({required this.sendCommand});

  final void Function(NesCommand command) sendCommand;

  FrameHandle? _latest;

  void addFrame(FrameEvent event) {
    if (_latest case final previous?) {
      sendCommand(ReleaseFrameCommand(pointerAddress: previous.pointerAddress));
    }

    _latest = FrameHandle(
      bytes: Pointer<Uint8>.fromAddress(
        event.pointerAddress,
      ).asTypedList(event.width * event.height * 4),
      width: event.width,
      height: event.height,
      pointerAddress: event.pointerAddress,
    );

    notifyListeners();
  }

  @override
  FrameHandle? takeFrame() {
    final frame = _latest;

    _latest = null;

    return frame;
  }

  @override
  void releaseFrame(FrameHandle handle) {
    sendCommand(ReleaseFrameCommand(pointerAddress: handle.pointerAddress));
  }

  void clear() {
    if (_latest case final frame?) {
      releaseFrame(frame);
    }

    _latest = null;
  }
}
