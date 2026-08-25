import 'dart:typed_data';

// ignore: avoid_classes_with_only_static_members
abstract final class FrameBufferMemory {
  static final Expando<Uint32List> _words = Expando<Uint32List>();

  static Uint8List allocate({required int wordCount}) {
    final buffer = Uint8List(wordCount * 4);

    _words[buffer] = buffer.buffer.asUint32List(0, wordCount);

    return buffer;
  }

  static Uint32List words(Uint8List buffer) =>
      _words[buffer] ??
      (throw ArgumentError('buffer was not allocated by FrameBufferMemory'));

  static int? pointerAddress(Uint8List buffer) => null;
}
