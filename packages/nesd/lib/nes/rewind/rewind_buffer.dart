import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/rewind/rewind_extension.dart';
import 'package:nesd/nes/rewind/rewind_frame_lane.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';
import 'package:nesd/nes/rewind/rewind_thumbnails.dart';
import 'package:nesd/nes/rewind/rewind_walk.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/util/ring_buffer.dart';

sealed class RewindItem {
  RewindItem({required this.state, required this.frame});

  final Uint8List state;

  final Uint8List frame;

  int get length => state.length + frame.length;
}

/// Marks the first state of a diff chain; carries no payload because
/// popping it only signals that the chain is exhausted.
class ChainStartRewindItem extends RewindItem {
  ChainStartRewindItem() : super(state: Uint8List(0), frame: Uint8List(0));
}

/// LZ4-compressed XOR diffs that recover the previous snapshot from the
/// snapshot that follows it in the chain.
class DiffRewindItem extends RewindItem {
  DiffRewindItem({required super.state, required super.frame});
}

class RewindSnapshot {
  const RewindSnapshot({required this.state, required this.frame});

  final NESState state;
  final Uint8List? frame;
}

class RewindBuffer {
  RewindBuffer({required int size, this.thumbnailStride = 60, this._profiler})
    : _buffer = RingBuffer<RewindItem, List<RewindItem>>(
        buffer: List<RewindItem>.generate(size, (_) => ChainStartRewindItem()),
      );

  final int thumbnailStride;

  final RewindProfiler? _profiler;
  final RingBuffer<RewindItem, List<RewindItem>> _buffer;

  RewindThumbnails? _thumbnails;

  int _sequence = 0;

  Uint8List _currentPool = Uint8List(0);
  int _currentLength = 0;
  bool _hasCurrent = false;

  RewindFrameLane? _frameLane;

  Uint8List? get _currentView => _hasCurrent
      ? Uint8List.view(_currentPool.buffer, 0, _currentLength)
      : null;

  int _bytes = 0;

  int get size => _bytes;

  int get itemCapacity => _buffer.size;

  int get newestSequence => _sequence - 1;

  int get oldestSequence => _sequence - _buffer.current;

  int get itemCount => _buffer.current;

  int get thumbnailWidth => _thumbnails?.width ?? 0;

  int get thumbnailHeight => _thumbnails?.height ?? 0;

  List<RewindThumbnail> thumbnails() => _thumbnails?.snapshot() ?? const [];

  void clear() {
    _buffer.clear();
    _frameLane?.clear();
    _thumbnails?.clear();

    _hasCurrent = false;
    _bytes = 0;
    _sequence = 0;
  }

  void dispose() {
    clear();

    _frameLane?.dispose();
    _frameLane = null;
    _thumbnails = null;
  }

  void add(NESState state) {
    scheduleMicrotask(() => _addState(state));
  }

  RewindSnapshot? pop() {
    final current = _currentView;

    if (current == null) {
      return null;
    }

    final item = _buffer.popEnd();

    if (item != null) {
      _bytes -= item.length;
    }

    try {
      final state = NESState.fromBytes(current);
      final lane = _frameLane;
      final Uint8List? frame;

      switch (item) {
        case DiffRewindItem():
          _setCurrent(item.state.decompress().diffWith(current));

          frame = lane != null && lane.hasCurrent && item.frame.isNotEmpty
              ? lane.restore(item.frame)
              : null;
        case ChainStartRewindItem() || null:
          frame = lane != null && lane.hasCurrent ? lane.current : null;

          _hasCurrent = false;
          lane?.clear();
      }

      return RewindSnapshot(state: state, frame: frame);
    } on NesdException catch (e) {
      // a corrupted chain must not crash the emulator
      log.emulator.warning('Rewind chain corrupted; buffer cleared', error: e);

      clear();

      return null;
      // binarize throws RangeError on truncated payloads
      // ignore: avoid_catching_errors
    } on RangeError catch (e) {
      log.emulator.warning(
        'Rewind payload truncated; buffer cleared',
        error: e,
      );

      clear();

      return null;
    }
  }

  RewindWalk? beginWalk() {
    final current = _currentView;

    if (current == null) {
      return null;
    }

    final lane = _frameLane;

    return RewindWalk(
      itemAt: _itemFromEnd,
      itemCount: _buffer.current,
      seedState: current,
      seedFrame: lane != null && lane.hasCurrent
          ? Uint8List.fromList(lane.current)
          : null,
    );
  }

  void commitWalk(RewindWalk walk) {
    for (var i = 0; i < walk.position; i++) {
      final item = _buffer.popEnd();

      if (item == null) {
        break;
      }

      _bytes -= item.length;
    }

    _sequence -= walk.position;

    _thumbnails?.truncateAfter(newestSequence);

    _setCurrent(walk.stateBytes);

    if (walk.frame case final frame?) {
      _laneFor(frame).setCurrent(frame);
    }

    walk.dispose();
  }

  RewindItem? _itemFromEnd(int position) {
    final index = _buffer.current - 1 - position;

    if (index < 0) {
      return null;
    }

    return _buffer.peek(index);
  }

  void _addState(NESState state) {
    if (_buffer.isFull) {
      final evicted = _buffer.popFront();

      if (evicted != null) {
        _bytes -= evicted.length;
      }
    }

    final profiler = _profiler;
    final watch = profiler == null ? null : (Stopwatch()..start());

    final serialized = state.serialize(includeFrame: false);

    if (profiler != null) {
      profiler.addSerialize(watch!.elapsedMicroseconds);
      watch.reset();
    }

    final presented = state.ppuState.frameBuffer?.presentedPixels;
    final previous = _currentView;

    final RewindItem item;

    if (previous == null) {
      _captureFrame(presented);

      item = ChainStartRewindItem();
    } else {
      final diff = previous.diffWith(serialized);

      if (profiler != null) {
        profiler.addDiff(watch!.elapsedMicroseconds);
        watch.reset();
      }

      final frame = _captureFrame(presented);

      item = DiffRewindItem(state: diff.compress(), frame: frame);

      if (profiler != null) {
        profiler.addCompress(watch!.elapsedMicroseconds);
      }
    }

    _captureThumbnail(_sequence, presented);

    _sequence++;

    _buffer.append(item);

    _bytes += item.length;

    _setCurrent(serialized);
  }

  RewindFrameLane _laneFor(Uint8List presented) =>
      _frameLane ??= RewindFrameLane(size: presented.length);

  Uint8List _captureFrame(Uint8List? presented) {
    if (presented == null) {
      return Uint8List(0);
    }

    final lane = _laneFor(presented);

    if (!lane.hasCurrent) {
      lane.setCurrent(presented);

      return Uint8List(0);
    }

    return lane.captureDiff(presented);
  }

  RewindThumbnails _thumbnailsFor(Uint8List presented) {
    const sourceWidth = 256;

    return _thumbnails ??= RewindThumbnails(
      capacity: _buffer.size ~/ thumbnailStride + 1,
      sourceWidth: sourceWidth,
      sourceHeight: presented.length ~/ (sourceWidth * 4),
    );
  }

  void _captureThumbnail(int sequence, Uint8List? presented) {
    if (presented == null || sequence % thumbnailStride != 0) {
      return;
    }

    _thumbnailsFor(presented).add(sequence, presented);
  }

  void _setCurrent(Uint8List serialized) {
    if (_currentPool.length < serialized.length) {
      _currentPool = Uint8List(serialized.length);
    }

    _currentPool.setRange(0, serialized.length, serialized);
    _currentLength = serialized.length;
    _hasCurrent = true;
  }
}
