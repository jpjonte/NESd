import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ignore: avoid_classes_with_only_static_members
abstract final class FrameBufferMemory {
  static final Expando<Pointer<Uint8>> _pointers = Expando<Pointer<Uint8>>();
  static final Expando<Uint32List> _words = Expando<Uint32List>();
  static final Finalizer<Pointer<Uint8>> _finalizer = Finalizer<Pointer<Uint8>>(
    (pointer) => calloc.free(pointer),
  );

  static Uint8List allocate({required int wordCount}) {
    final size = wordCount * 4;

    // make sure memory is initialized to 0 so there are no artifacts
    final pointer = calloc<Uint8>(size);
    final buffer = pointer.asTypedList(size);

    _pointers[buffer] = pointer;
    _words[buffer] = pointer.cast<Uint32>().asTypedList(wordCount);
    _finalizer.attach(buffer, pointer);

    return buffer;
  }

  static Uint32List words(Uint8List buffer) =>
      _words[buffer] ??
      (throw ArgumentError('buffer was not allocated by FrameBufferMemory'));

  static int? pointerAddress(Uint8List buffer) => _pointers[buffer]?.address;
}
