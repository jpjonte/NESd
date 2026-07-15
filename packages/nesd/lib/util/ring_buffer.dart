import 'dart:math';

class RingBuffer<T, S extends List<T>> {
  RingBuffer({required this.buffer}) : size = buffer.length;

  final S buffer;

  late final int size;

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
      target.setRange(0, readSize, buffer, _start);
    } else {
      // read wraps around
      final firstSegmentSize = this.size - _start;

      target
        ..setRange(0, firstSegmentSize, buffer, _start)
        ..setRange(firstSegmentSize, readSize, buffer);
    }

    _start = (_start + readSize) % this.size;

    return readSize;
  }

  int write(S data) {
    final writeSize = min(data.length, remaining);

    if (_end + writeSize <= size) {
      buffer.setRange(_end, _end + writeSize, data);
    } else {
      // write wraps around
      final firstSegmentSize = size - _end;

      buffer
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

    buffer[_end] = item;
    _end = (_end + 1) % size;
  }

  T? popFront() {
    if (isEmpty) {
      return null;
    }

    final item = buffer[_start];

    _start = (_start + 1) % size;

    return item;
  }

  T? popEnd() {
    if (isEmpty) {
      return null;
    }

    _end = (_end - 1) % size;

    return buffer[_end];
  }

  T? peekFront() {
    if (isEmpty) {
      return null;
    }

    return buffer[_start];
  }

  T? peek(int position) {
    if (position >= current) {
      return null;
    }

    final index = (_start + position) % size;

    return buffer[index];
  }

  T? peekEnd() {
    if (isEmpty) {
      return null;
    }

    return buffer[(_end - 1) % size];
  }
}
