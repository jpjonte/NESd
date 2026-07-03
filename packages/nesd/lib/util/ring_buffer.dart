import 'dart:math';

class RingBuffer<T, S extends List<T>> {
  RingBuffer({required this.bufferConstructor, required this.size}) {
    _buffer = bufferConstructor(size);
  }

  final S Function(int) bufferConstructor;

  late final S _buffer;

  final int size;

  int _start = 0;
  int _end = 0;

  int get current => (_end - _start) % size;
  // subtract 1 so that a full buffer is not considered empty
  // (because start == end => size == 0)
  int get remaining => size - current - 1;

  bool get isEmpty => current < 1;
  bool get isFull => remaining < 1;

  void clear() {
    _start = 0;
    _end = 0;
  }

  int readInto(S target, int size) {
    final readSize = min(min(size, current), target.length);

    if (_start + readSize <= this.size) {
      target.setRange(0, readSize, _buffer, _start);
    } else {
      // read wraps around
      final firstSegmentSize = this.size - _start;

      target
        ..setRange(0, firstSegmentSize, _buffer, _start)
        ..setRange(firstSegmentSize, readSize, _buffer);
    }

    _start = (_start + readSize) % this.size;

    return readSize;
  }

  int write(S data) {
    final writeSize = min(data.length, remaining);

    if (_end + writeSize <= size) {
      _buffer.setRange(_end, _end + writeSize, data);
    } else {
      // write wraps around
      final firstSegmentSize = size - _end;

      _buffer
        ..setRange(_end, size, data)
        ..setRange(0, writeSize - firstSegmentSize, data, firstSegmentSize);
    }

    _end = (_end + writeSize) % size;

    return writeSize;
  }

  void append(T item) {
    if (isFull) {
      throw Exception('Buffer is full');
    }

    _buffer[_end] = item;
    _end = (_end + 1) % size;
  }

  T? popFront() {
    if (isEmpty) {
      return null;
    }

    final item = _buffer[_start];

    _start = (_start + 1) % size;

    return item;
  }

  T? popEnd() {
    if (isEmpty) {
      return null;
    }

    _end = (_end - 1) % size;

    return _buffer[_end];
  }

  T? peekFront() {
    if (isEmpty) {
      return null;
    }

    return _buffer[_start];
  }

  T? peek(int position) {
    if (position >= current) {
      return null;
    }

    final index = (_start + position) % size;

    return _buffer[index];
  }

  T? peekEnd() {
    if (isEmpty) {
      return null;
    }

    return _buffer[(_end - 1) % size];
  }
}
