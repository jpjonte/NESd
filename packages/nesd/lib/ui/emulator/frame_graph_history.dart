import 'dart:math';

import 'package:flutter/foundation.dart';

class FrameGraphHistory extends ChangeNotifier {
  FrameGraphHistory({required this.capacity})
    : _work = Int32List(capacity),
      _sleep = Int32List(capacity);

  final int capacity;

  final Int32List _work;
  final Int32List _sleep;

  int _length = 0;
  int _next = 0;

  int get length => _length;

  int workAt(int index) => _work[_offsetOf(index)];

  int sleepAt(int index) => _sleep[_offsetOf(index)];

  void add({
    required int frameTimeMicroseconds,
    required int sleepTimeMicroseconds,
  }) {
    final total = max(0, frameTimeMicroseconds);
    final sleep = min(max(0, sleepTimeMicroseconds), total);

    _work[_next] = total - sleep;
    _sleep[_next] = sleep;

    _next = (_next + 1) % capacity;

    if (_length < capacity) {
      _length++;
    }

    notifyListeners();
  }

  void clear() {
    _length = 0;
    _next = 0;

    notifyListeners();
  }

  int _offsetOf(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }

    return (_next - _length + index + capacity) % capacity;
  }
}
