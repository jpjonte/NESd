import 'dart:math';
import 'dart:typed_data';

class AudioBuffer {
  AudioBuffer(int size) : _buffer = Float32List(size);

  final Float32List _buffer;

  int _start = 0;
  int _end = 0;

  int get size => _buffer.length;
  int get current => (_end - _start) % size;
  // subtract 1 so that a full buffer is not considered empty
  // (because start == end)
  int get remaining => size - current - 1;

  void clear() {
    _start = 0;
    _end = 0;
  }

  Float32List read(int size) {
    final readSize = min(size, current);
    final samples = Float32List(readSize);

    if (_start + readSize < _buffer.length) {
      samples.setAll(0, _buffer.sublist(_start, _start + readSize));
    } else {
      // read wraps around

      final firstSegmentSize = _buffer.length - _start;
      final secondSegmentSize = readSize - firstSegmentSize;

      samples
        ..setAll(0, _buffer.sublist(_start, _buffer.length))
        ..setAll(firstSegmentSize, _buffer.sublist(0, secondSegmentSize));
    }

    _start = (_start + readSize) % _buffer.length;

    return samples;
  }

  int write(Float32List samples) {
    final writeSize = min(samples.length, remaining);

    if (_end + writeSize < size) {
      _buffer.setAll(_end, samples.sublist(0, writeSize));
    } else {
      // write wraps around

      final firstSegmentSize = size - _end;

      _buffer
        ..setAll(_end, samples.sublist(0, firstSegmentSize))
        ..setAll(0, samples.sublist(firstSegmentSize, writeSize));
    }

    _end = (_end + writeSize) % size;

    return writeSize;
  }
}
