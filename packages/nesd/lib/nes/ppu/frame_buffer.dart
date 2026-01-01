import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:ffi/ffi.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class FrameBuffer {
  FrameBuffer({required this.width, required this.height})
    : size = width * height * 4 {
    pixels = _allocateBuffer();
    pixels32 = _bufferUint32[pixels]!;
  }

  factory FrameBuffer.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => FrameBuffer._version0(reader),
      _ => throw InvalidSerializationVersion('FrameBuffer', version),
    };
  }

  factory FrameBuffer._version0(PayloadReader reader) {
    return FrameBuffer(width: reader.get(uint32), height: reader.get(uint32))
      ..setPixels(reader.get(uint8List(lengthType: uint32)));
  }

  final int width;
  final int height;
  final int size;

  late Uint8List pixels;
  late Uint32List pixels32;

  final Queue<Uint8List> _ready = Queue<Uint8List>();
  final List<Uint8List> _available = <Uint8List>[];
  final Set<Uint8List> _inUse = <Uint8List>{};

  static const int _maxAvailable = 2;
  static const int _maxQueued = 2;
  static final Expando<Pointer<Uint8>> _bufferPointers =
      Expando<Pointer<Uint8>>();
  static final Expando<Uint32List> _bufferUint32 = Expando<Uint32List>();
  static final Finalizer<Pointer<Uint8>> _bufferFinalizer =
      Finalizer<Pointer<Uint8>>((pointer) => malloc.free(pointer));

  int getPixelBrightness(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return 0;
    }

    final color = pixels32[y * width + x];

    final blue = color & 0xff;
    final green = (color >> 8) & 0xff;
    final red = (color >> 16) & 0xff;

    return red + green + blue;
  }

  void setPixel(int x, int y, int color) {
    final index = y * width + x;

    pixels32[index] = _packColor(color);
  }

  void setPixelWithBase(int base, int x, int color) {
    pixels32[base + x] = color;
  }

  void setPixels(Uint8List pixels) {
    resetBuffers();

    this.pixels.setAll(0, pixels);
  }

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint32, width)
      ..set(uint32, height)
      ..set(uint8List(lengthType: uint32), pixels);
  }

  void swap() {
    while (_ready.length >= _maxQueued) {
      final dropped = _ready.removeFirst();

      if (_available.length < _maxAvailable) {
        _available.add(dropped);
      }
    }

    _ready.add(pixels);

    pixels = _available.isNotEmpty
        ? _available.removeLast()
        : _allocateBuffer();
    pixels32 = _bufferUint32[pixels]!;
  }

  Uint8List? takeReadyBuffer() {
    if (_ready.isEmpty) {
      return null;
    }

    final buffer = _ready.removeFirst();

    _inUse.add(buffer);

    return buffer;
  }

  void releaseDisplayBuffer(Uint8List buffer) {
    if (!_inUse.remove(buffer)) {
      return;
    }

    if (_available.length < _maxAvailable) {
      _available.add(buffer);
    }
  }

  void resetBuffers() {
    _ready.clear();
    _inUse.clear();
    _available.clear();
  }

  int? pointerForBuffer(Uint8List buffer) => _bufferPointers[buffer]?.address;

  Uint8List _allocateBuffer() {
    final pointer = malloc<Uint8>(size);
    final buffer = pointer.asTypedList(size);
    final buffer32 = pointer.cast<Uint32>().asTypedList(width * height);

    _bufferPointers[buffer] = pointer;
    _bufferUint32[buffer] = buffer32;
    _bufferFinalizer.attach(buffer, pointer);

    return buffer;
  }

  static int _packColor(int rgb) {
    final red = (rgb >> 16) & 0xff;
    final green = (rgb >> 8) & 0xff;
    final blue = rgb & 0xff;

    return 0xff000000 | (blue << 16) | (green << 8) | red;
  }
}
