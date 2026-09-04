import 'dart:typed_data';

// Rewind is FFI-only, so this lane never runs on web. Throw so it cannot be
// silently enabled.
class RewindFrameLane {
  RewindFrameLane({required this.size}) {
    throw UnsupportedError('rewind is not available on web');
  }

  final int size;

  bool get hasCurrent => false;

  Uint8List get current =>
      throw UnsupportedError('rewind is not available on web');

  void setCurrent(Uint8List presented) {}

  Uint8List captureDiff(Uint8List presented) =>
      throw UnsupportedError('rewind is not available on web');

  Uint8List restore(Uint8List diff) =>
      throw UnsupportedError('rewind is not available on web');

  void clear() {}

  void dispose() {}
}
