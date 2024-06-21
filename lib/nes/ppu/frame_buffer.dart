import 'package:binarize/binarize.dart';

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

  void setPixels(Uint8List pixels) {
    this.pixels.setAll(0, pixels);
  }
}

class _FrameBufferContract extends BinaryContract<FrameBuffer>
    implements FrameBuffer {
  _FrameBufferContract()
      : super(
          FrameBuffer(
            width: 0,
            height: 0,
          ),
        );

  @override
  FrameBuffer order(FrameBuffer contract) {
    return FrameBuffer(width: contract.width, height: contract.height);
  }

  @override
  int get width => type(uint32, (o) => o.width);

  @override
  int get height => type(uint32, (o) => o.height);

  @override
  Uint8List get pixels => Uint8List.fromList(
        type(list(uint8), (o) => o.pixels),
      );

  @override
  void setPixel(int x, int y, int color) {}

  @override
  void setPixels(Uint8List pixels) {}
}

final frameBufferContract = _FrameBufferContract();
