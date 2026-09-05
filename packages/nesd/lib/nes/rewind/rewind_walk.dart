import 'dart:typed_data';

import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/rewind/rewind_extension.dart';
import 'package:nesd/nes/rewind/rewind_frame_lane.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

class RewindWalk {
  RewindWalk({
    required this._itemAt,
    required this._itemCount,
    required Uint8List seedState,
    required this._seedFrame,
  }) : _seedState = Uint8List.fromList(seedState) {
    _reseed();
  }

  final RewindItem? Function(int position) _itemAt;
  final int _itemCount;
  final Uint8List _seedState;
  final Uint8List? _seedFrame;

  RewindFrameLane? _lane;

  Uint8List _state = Uint8List(0);
  Uint8List? _frame;

  int _position = 0;

  int get position => _position;

  int get itemCount => _itemCount;

  Uint8List get stateBytes => _state;

  Uint8List? get frame => _frame;

  NESState buildState() => NESState.fromBytes(_state);

  bool seekTo(int targetPosition, {required int budget}) {
    if (_disposed) {
      return true;
    }

    final target = targetPosition.clamp(0, _itemCount);

    var replayed = 0;

    while (_position > target && replayed < budget) {
      if (!_stepForward()) {
        _reseed();

        break;
      }

      replayed++;
    }

    while (_position < target && replayed < budget) {
      if (!_stepBack()) {
        return true;
      }

      replayed++;
    }

    return _position == target;
  }

  void dispose() {
    _disposed = true;

    _lane?.dispose();
    _lane = null;

    _frame = null;
  }

  bool _disposed = false;

  final List<int> _lengthAt = [];
  final List<Uint8List> _tailAt = [];

  static final _noTail = Uint8List(0);

  void _reseed() {
    _state = Uint8List.fromList(_seedState);
    _position = 0;

    _lengthAt.clear();
    _tailAt.clear();

    final seedFrame = _seedFrame;

    if (seedFrame == null) {
      _frame = null;

      return;
    }

    (_lane ??= RewindFrameLane(size: seedFrame.length)).setCurrent(seedFrame);

    _frame = seedFrame;
  }

  bool _stepBack() {
    final item = _itemAt(_position);

    if (item is! DiffRewindItem) {
      return false;
    }

    final diff = item.state.decompress();
    final previous = _state;

    _record(previous, diff.length);

    _state = diff.diffWith(previous);
    _position++;

    final lane = _lane;

    if (lane != null && lane.hasCurrent && item.frame.isNotEmpty) {
      lane.restore(item.frame);

      _frame = lane.current;
    }

    return true;
  }

  static Uint8List _resize(Uint8List restored, int length, Uint8List tail) {
    if (restored.length == length) {
      return restored;
    }

    if (restored.length > length) {
      return Uint8List.sublistView(restored, 0, length);
    }

    return Uint8List(length)
      ..setRange(0, restored.length, restored)
      ..setRange(restored.length, length, tail);
  }

  void _record(Uint8List state, int diffLength) {
    while (_lengthAt.length <= _position) {
      _lengthAt.add(0);
      _tailAt.add(_noTail);
    }

    _lengthAt[_position] = state.length;
    _tailAt[_position] = state.length > diffLength
        ? Uint8List.fromList(Uint8List.sublistView(state, diffLength))
        : _noTail;
  }

  bool _stepForward() {
    if (_position == 0 || _position > _lengthAt.length) {
      return false;
    }

    final item = _itemAt(_position - 1);

    if (item is! DiffRewindItem) {
      return false;
    }

    final length = _lengthAt[_position - 1];
    final tail = _tailAt[_position - 1];
    final restored = item.state.decompress().diffWith(_state);

    if (restored.length < length && tail.length != length - restored.length) {
      return false;
    }

    _state = _resize(restored, length, tail);
    _position--;

    final lane = _lane;

    if (lane != null && lane.hasCurrent && item.frame.isNotEmpty) {
      lane.restore(item.frame);

      _frame = lane.current;
    }

    return true;
  }
}
