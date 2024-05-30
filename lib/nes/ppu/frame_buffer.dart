import 'dart:typed_data';

class FrameBuffer {
  FrameBuffer({
    required this.width,
    required this.height,
  }) : pixels = Uint8List(height * width * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  void setPixel(int x, int y, int color) {
    final index = (y * width + x) * 4;

    pixels[index] = color >> 16 & 0xff;
    pixels[index + 1] = color >> 8 & 0xff;
    pixels[index + 2] = color & 0xff;
    pixels[index + 3] = 0xff;
  }
}
