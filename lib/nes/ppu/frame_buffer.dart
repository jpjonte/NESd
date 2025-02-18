import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class FrameBuffer {
  FrameBuffer({required this.width, required this.height})
    : pixels = Uint8List(height * width * 4);

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
  final Uint8List pixels;

  void setPixel(int x, int y, int color) {
    final index = (y * width + x) * 4;

    pixels[index] = color >> 16;
    pixels[index + 1] = color >> 8;
    pixels[index + 2] = color;
    pixels[index + 3] = 0xff;
  }

  void setPixels(Uint8List pixels) {
    this.pixels.setAll(0, pixels);
  }

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint32, width)
      ..set(uint32, height)
      ..set(uint8List(lengthType: uint32), pixels);
  }

  void clear() {
    pixels.fillRange(0, pixels.length, 0);
  }
}
