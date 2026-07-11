import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/rewind/rewind_extension.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/util/ring_buffer.dart';

sealed class RewindItem {
  RewindItem(this.compressed);

  final Uint8List compressed;
}

/// Marks the first state of a diff chain; carries no payload because
/// popping it only signals that the chain is exhausted.
class ChainStartRewindItem extends RewindItem {
  ChainStartRewindItem() : super(Uint8List(0));
}

/// LZ4-compressed XOR diff that recovers the previous state from the
/// state that follows it in the chain.
class DiffRewindItem extends RewindItem {
  DiffRewindItem(super.compressed);
}

class RewindBuffer {
  RewindBuffer({required int size, this._profiler})
    : _buffer = RingBuffer<RewindItem, List<RewindItem>>(
        buffer: List<RewindItem>.generate(size, (_) => ChainStartRewindItem()),
      );

  final RewindProfiler? _profiler;
  final RingBuffer<RewindItem, List<RewindItem>> _buffer;

  /// Serialization of the newest state that has not been popped yet.
  Uint8List? _current;

  int _bytes = 0;

  /// The size of the buffer in bytes.
  int get size => _bytes;

  void clear() {
    _buffer.clear();

    _current = null;
    _bytes = 0;
  }

  void add(NESState state) {
    scheduleMicrotask(() => _addState(state));
  }

  NESState? pop() {
    final current = _current;

    if (current == null) {
      return null;
    }

    final item = _buffer.popEnd();

    if (item != null) {
      _bytes -= item.compressed.length;
    }

    try {
      _current = switch (item) {
        DiffRewindItem() => item.compressed.decompress().diffWith(current),
        ChainStartRewindItem() || null => null,
      };

      return NESState.fromBytes(current);
    } on NesdException {
      // a corrupted chain must not crash the emulator
      clear();

      return null;
      // binarize throws RangeError on truncated payloads
      // ignore: avoid_catching_errors
    } on RangeError {
      clear();

      return null;
    }
  }

  void _addState(NESState state) {
    if (_buffer.isFull) {
      final evicted = _buffer.popFront();

      if (evicted != null) {
        _bytes -= evicted.compressed.length;
      }
    }

    final watch = _profiler == null ? null : (Stopwatch()..start());

    final serialized = state.serialize();

    if (watch != null) {
      _profiler!.addSerialize(watch.elapsedMicroseconds);
      watch.reset();
    }

    final previous = _current;

    final RewindItem item;

    if (previous == null) {
      item = ChainStartRewindItem();
    } else {
      final diff = previous.diffWith(serialized);

      if (watch != null) {
        _profiler!.addDiff(watch.elapsedMicroseconds);
        watch.reset();
      }

      item = DiffRewindItem(diff.compress());

      if (watch != null) {
        _profiler!.addCompress(watch.elapsedMicroseconds);
      }
    }

    _buffer.append(item);

    _bytes += item.compressed.length;
    _current = serialized;
  }
}
