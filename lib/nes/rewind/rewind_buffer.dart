import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/nes/rewind/rewind_extension.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/nes/serialization/raw_uint8_list.dart';
import 'package:nesd/util/ring_buffer.dart';

sealed class RewindItem {
  RewindItem(this.compressed);

  List<int> compressed;

  RawUint8List? _uncompressed;

  List<int> get data =>
      _uncompressed ??= RawUint8List.fromList(compressed.decompress());

  int get size => compressed.length + (_uncompressed?.length ?? 0);

  void compress() => _uncompressed = null;
}

class DummyRewindItem extends RewindItem {
  DummyRewindItem() : super(Uint8List(0));
}

class FullRewindItem extends RewindItem {
  FullRewindItem(List<int> data) : super(data.compress()) {
    _uncompressed = RawUint8List.fromList(data);
  }

  NESState get state => NESState.fromBytes(data);
}

class DiffRewindItem extends RewindItem {
  DiffRewindItem(List<int> previousData, List<int> data)
    : super(data.diff(previousData).compress());

  NESState getState(FullRewindItem fullState) {
    data.diff(fullState.data);

    return NESState.fromBytes(data);
  }
}

class RewindBuffer {
  RewindBuffer({required int size, this.fullStateThreshold = 60})
    : _buffer = RingBuffer<RewindItem, List<RewindItem>>(
        size: size,
        bufferConstructor:
            (size) =>
                List<RewindItem>.generate(size, (index) => DummyRewindItem()),
      );

  /// The size of the buffer in bytes.
  int get size {
    var size = 0;

    for (var i = 0; i < _buffer.current; i++) {
      size += _buffer.peek(i)?.size ?? 0;
    }

    return size;
  }

  final int fullStateThreshold;

  final RingBuffer<RewindItem, List<RewindItem>> _buffer;

  void reset() => _buffer.clear();

  void add(NESState state) {
    scheduleMicrotask(() {
      if (_buffer.isFull) {
        // pop the oldest full state
        _buffer.popFront();

        // pop all diff states until we find a full state
        while (_buffer.peekFront() is DiffRewindItem) {
          _buffer.popFront();
        }
      }

      final fullState = _buffer.current % fullStateThreshold == 0;

      final serialized = state.serialize();
      final previous = _getLastFullState();

      if (fullState) {
        if (previous != null) {
          previous.compress();
        }

        final item = FullRewindItem(serialized);

        _buffer.append(item);
      } else {
        final item = DiffRewindItem(previous!.data, serialized);

        _buffer.append(item);
      }
    });
  }

  NESState? pop() {
    final item = _buffer.popEnd();

    if (item == null) {
      return null;
    }

    return switch (item) {
      FullRewindItem() => item.state,
      DiffRewindItem() => _getDiffState(item),
      DummyRewindItem() => null,
    };
  }

  FullRewindItem? _getLastFullState() {
    var position = _buffer.current;

    while (position >= 0) {
      final item = _buffer.peek(position);

      if (item is FullRewindItem) {
        return item;
      }

      position--;
    }

    return null;
  }

  NESState _getDiffState(DiffRewindItem item) {
    final lastFullState = _getLastFullState();

    return item.getState(lastFullState!);
  }
}
