import 'dart:io';
import 'dart:typed_data';

/// Appends raw float32 (host-endian) PCM to a file in chunked writes.
///
/// The audio path calls [add] once per frame (~800 samples at 48 kHz).
/// Buffering into a chunk keeps file IO down to roughly one write per
/// second. An IO failure (e.g. disk full) logs once and disables the
/// recorder instead of breaking audio output.
class PcmRecorder {
  PcmRecorder({required this.path, int chunkSamples = 48000})
    : _file = File(path).openSync(mode: FileMode.writeOnly),
      _chunk = Float32List(chunkSamples);

  final String path;

  final RandomAccessFile _file;
  final Float32List _chunk;

  int _index = 0;
  bool _failed = false;

  void add(Float32List samples) {
    if (_failed) {
      return;
    }

    for (var i = 0; i < samples.length; i++) {
      _chunk[_index++] = samples[i];

      if (_index == _chunk.length) {
        _flush();
      }
    }
  }

  void close() {
    _flush();

    try {
      _file.closeSync();
    } on FileSystemException {
      // _flush already logged; nothing left to salvage
    }
  }

  void _flush() {
    if (_index == 0 || _failed) {
      _index = 0;

      return;
    }

    try {
      _file.writeFromSync(_chunk.buffer.asUint8List(0, _index * 4));
    } on FileSystemException catch (e) {
      _failed = true;

      // ignore: avoid_print, logcat is the transport on device
      print('NESD_PCM_ERROR $e');
    }

    _index = 0;
  }
}
