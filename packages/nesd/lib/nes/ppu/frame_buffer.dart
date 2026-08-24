import 'dart:collection';
import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/ppu/frame_buffer_memory.dart';

class FrameBuffer {
  FrameBuffer({required this.width, required this.height})
    : size = width * height * 4 {
    pixels = _allocateBuffer();
    pixels32 = FrameBufferMemory.words(pixels);
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

  Uint8List? _presentedPixels;
  Uint32List? _presentedPixels32;

  static const int _maxAvailable = 2;
  static const int _maxQueued = 2;

  Uint8List get presentedPixels => _presentedPixels ?? pixels;

  int getPixelBrightness(int x, int y, {bool previousFrame = false}) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return 0;
    }

    final buffer = previousFrame ? _presentedPixels32 : pixels32;

    if (buffer == null) {
      return 0;
    }

    final color = buffer[y * width + x];

    final blue = color & 0xff;
    final green = (color >> 8) & 0xff;
    final red = (color >> 16) & 0xff;

    return red + green + blue;
  }

  void setPixel(int x, int y, int color) {
    final index = y * width + x;

    pixels32[index] = _packColor(color);
  }

  @pragma('vm:prefer-inline')
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
      ..set(uint8List(lengthType: uint32), presentedPixels);
  }

  void swap() {
    while (_ready.length >= _maxQueued) {
      final dropped = _ready.removeFirst();

      if (_available.length < _maxAvailable) {
        _available.add(dropped);
      }
    }

    _ready.add(pixels);

    _presentedPixels = pixels;
    _presentedPixels32 = pixels32;

    pixels = _available.isNotEmpty
        ? _available.removeLast()
        : _allocateBuffer();
    pixels32 = FrameBufferMemory.words(pixels);
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

    _presentedPixels = null;
    _presentedPixels32 = null;
  }

  int? pointerForBuffer(Uint8List buffer) =>
      FrameBufferMemory.pointerAddress(buffer);

  Uint8List _allocateBuffer() =>
      FrameBufferMemory.allocate(wordCount: width * height);

  static int _packColor(int rgb) {
    final red = (rgb >> 16) & 0xff;
    final green = (rgb >> 8) & 0xff;
    final blue = rgb & 0xff;

    return 0xff000000 | (blue << 16) | (green << 8) | red;
  }
}
