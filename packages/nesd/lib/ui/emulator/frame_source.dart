import 'package:flutter/foundation.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/frame_view.dart';

/// A frame taken from a [FrameSource], to be released exactly once.
class FrameHandle {
  const FrameHandle({
    required this.bytes,
    required this.width,
    required this.height,
    required this.id,
    this.pixelPointer,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  final int id;

  /// Native frame memory address for the GPU texture path. `null` on web.
  final int? pixelPointer;
}

abstract class FrameSource extends ChangeNotifier {
  FrameHandle? takeFrame();

  void releaseFrame(FrameHandle handle);
}

/// Holds at most the latest frame from the worker. A superseded frame is
/// released back to the worker's pool before the new one is stored.
class RemoteFrameSource extends FrameSource {
  RemoteFrameSource({required this.sendCommand});

  final void Function(NesCommand command) sendCommand;

  FrameHandle? _latest;

  void addFrame(FrameEvent event) {
    if (_latest case final previous?) {
      sendCommand(ReleaseFrameCommand(frameHandle: previous.id));
    }

    _latest = switch (event.pixels) {
      InlineFramePixels(:final bytes) => FrameHandle(
        bytes: bytes,
        width: event.width,
        height: event.height,
        id: event.frameHandle,
      ),
      PointerFramePixels(:final address) => FrameHandle(
        bytes: frameBytesFromAddress(address, event.width * event.height * 4),
        width: event.width,
        height: event.height,
        id: event.frameHandle,
        pixelPointer: address,
      ),
    };

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
    sendCommand(ReleaseFrameCommand(frameHandle: handle.id));
  }

  void clear() {
    if (_latest case final frame?) {
      releaseFrame(frame);
    }

    _latest = null;
  }
}
