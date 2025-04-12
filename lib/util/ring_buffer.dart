import 'dart:math';

class RingBuffer<T, S extends List<T>> {
  RingBuffer({required this.bufferConstructor, required int size}) {
    _buffer = bufferConstructor(size);
  }

  final S Function(int) bufferConstructor;

  late final S _buffer;

  int _start = 0;
  int _end = 0;

  int get size => _buffer.length;
  int get current => (_end - _start) % size;
  // subtract 1 so that a full buffer is not considered empty
  // (because start == end => size == 0)
  int get remaining => size - current - 1;

  void clear() {
    _start = 0;
    _end = 0;
  }

  S read(int size) {
    final readSize = min(size, current);
    final data = bufferConstructor(readSize);

    if (_start + readSize < _buffer.length) {
      data.setAll(0, _buffer.sublist(_start, _start + readSize));
    } else {
      // read wraps around

      final firstSegmentSize = _buffer.length - _start;
      final secondSegmentSize = readSize - firstSegmentSize;

      data
        ..setAll(0, _buffer.sublist(_start, _buffer.length))
        ..setAll(firstSegmentSize, _buffer.sublist(0, secondSegmentSize));
    }

    _start = (_start + readSize) % this.size;

    return data;
  }

  int write(S data) {
    final writeSize = min(data.length, remaining);

    if (_end + writeSize < size) {
      _buffer.setAll(_end, data.sublist(0, writeSize));
    } else {
      // write wraps around

      final firstSegmentSize = size - _end;

      _buffer
        ..setAll(_end, data.sublist(0, firstSegmentSize))
        ..setAll(0, data.sublist(firstSegmentSize, writeSize));
    }

    _end = (_end + writeSize) % size;

    return writeSize;
  }
}
