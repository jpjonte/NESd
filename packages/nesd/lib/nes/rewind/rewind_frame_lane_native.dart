import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/ppu/frame_buffer_memory.dart';
import 'package:nesd/nes/rewind/lz4_native.dart';

class RewindFrameLane {
  RewindFrameLane({required this.size})
    : _current = calloc<Uint8>(_checkedSize(size)),
      _scratch = calloc<Uint8>(size) {
    _finalizer.attach(this, [_current, _scratch], detach: this);
  }

  static final Finalizer<List<Pointer<Uint8>>> _finalizer = Finalizer(
    (pointers) => pointers.forEach(calloc.free),
  );

  /// The XOR step packs the frame as 32-bit words, so [size] must be a
  /// positive multiple of 4.
  static int _checkedSize(int size) {
    if (size <= 0 || size % 4 != 0) {
      throw ArgumentError.value(
        size,
        'size',
        'must be a positive multiple of 4',
      );
    }

    return size;
  }

  final int size;

  Pointer<Uint8> _current;
  Pointer<Uint8> _scratch;

  bool _hasCurrent = false;

  bool get hasCurrent => _hasCurrent;

  Uint8List get current => _current.asTypedList(size);

  void setCurrent(Uint8List presented) {
    _current.asTypedList(size).setAll(0, _checked(presented));
    _hasCurrent = true;
  }

  Uint8List captureDiff(Uint8List presented) {
    final source = _pointerOf(_checked(presented));

    _xorInto(_scratch, source, _current);

    final diff = Lz4.instance.compressPointer(_scratch, size);

    _current.asTypedList(size).setAll(0, presented);

    return diff;
  }

  Uint8List restore(Uint8List diff) {
    if (Lz4.instance.decompressInto(diff, _scratch, size) != size) {
      throw NesdException('rewind frame diff has the wrong length');
    }

    _xorInto(_scratch, _scratch, _current);

    final captured = _current;

    _current = _scratch;
    _scratch = captured;

    return captured.asTypedList(size);
  }

  void clear() {
    _hasCurrent = false;
  }

  void dispose() {
    _finalizer.detach(this);
    calloc
      ..free(_current)
      ..free(_scratch);
  }

  Uint8List _checked(Uint8List presented) {
    if (presented.length != size) {
      throw ArgumentError.value(
        presented.length,
        'presented.length',
        'must be $size',
      );
    }

    return presented;
  }

  static Pointer<Uint8> _pointerOf(Uint8List buffer) {
    final address = FrameBufferMemory.pointerAddress(buffer);

    if (address == null) {
      throw ArgumentError('frame was not allocated by FrameBufferMemory');
    }

    return Pointer<Uint8>.fromAddress(address);
  }

  void _xorInto(Pointer<Uint8> dst, Pointer<Uint8> a, Pointer<Uint8> b) {
    final words = size >> 2;
    final target = dst.cast<Uint32>().asTypedList(words);
    final left = a.cast<Uint32>().asTypedList(words);
    final right = b.cast<Uint32>().asTypedList(words);

    for (var i = 0; i < words; i++) {
      target[i] = left[i] ^ right[i];
    }
  }
}
