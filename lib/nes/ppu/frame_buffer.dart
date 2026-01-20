import 'dart:collection';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class FrameBuffer {
  FrameBuffer({required this.width, required this.height})
    : size = width * height * 4,
      pixels = Uint8List(width * height * 4);

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

  Uint8List pixels;

  final Queue<Uint8List> _ready = Queue<Uint8List>();
  final List<Uint8List> _available = <Uint8List>[];
  final Set<Uint8List> _inUse = <Uint8List>{};

  static const int _maxAvailable = 2;
  static const int _maxQueued = 2;

  int getPixelBrightness(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return 0;
    }

    final base = (y * width + x) * 4;

    final red = pixels[base];
    final green = pixels[base + 1];
    final blue = pixels[base + 2];

    return red + green + blue;
  }

  void setPixel(int x, int y, int color) {
    final index = (y * width + x) * 4;

    // no need to mask with 0xff because we are using Uint8List
    pixels[index] = color >> 16;
    pixels[index + 1] = color >> 8;
    pixels[index + 2] = color;
    pixels[index + 3] = 0xff;
  }

  void setPixelWithBase(int base, int x, int color) {
    final index = base + (x * 4);

    // no need to mask with 0xff because we are using Uint8List
    pixels[index] = color >> 16;
    pixels[index + 1] = color >> 8;
    pixels[index + 2] = color;
    pixels[index + 3] = 0xff;
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

    pixels = _available.isNotEmpty ? _available.removeLast() : Uint8List(size);
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
}
