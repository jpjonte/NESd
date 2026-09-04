import 'dart:typed_data';

class RewindThumbnail {
  const RewindThumbnail({required this.sequence, required this.pixels});

  final int sequence;

  final Uint8List pixels;
}

class RewindThumbnails {
  RewindThumbnails({
    required this.capacity,
    required this.sourceWidth,
    required this.sourceHeight,
    this.scale = 4,
  }) : width = sourceWidth ~/ scale,
       height = sourceHeight ~/ scale,
       _sequences = Int64List(capacity),
       _entries = List<Uint8List>.generate(
         capacity,
         (_) => Uint8List(sourceWidth ~/ scale * (sourceHeight ~/ scale) * 4),
       );

  final int capacity;
  final int sourceWidth;
  final int sourceHeight;
  final int scale;

  final int width;
  final int height;

  final Int64List _sequences;
  final List<Uint8List> _entries;

  int _start = 0;
  int _length = 0;

  int get length => _length;

  void add(int sequence, Uint8List presented) {
    final index = (_start + _length) % capacity;

    _downsampleInto(presented, _entries[index]);
    _sequences[index] = sequence;

    if (_length < capacity) {
      _length++;

      return;
    }

    _start = (_start + 1) % capacity;
  }

  void clear() {
    _start = 0;
    _length = 0;
  }

  List<RewindThumbnail> snapshot() =>
      List<RewindThumbnail>.generate(_length, (i) {
        final index = (_start + i) % capacity;

        return RewindThumbnail(
          sequence: _sequences[index],
          pixels: _entries[index],
        );
      });

  void _downsampleInto(Uint8List source, Uint8List target) {
    final blockPixels = scale * scale;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var r = 0;
        var g = 0;
        var b = 0;
        var a = 0;

        for (var dy = 0; dy < scale; dy++) {
          final row = (y * scale + dy) * sourceWidth;

          for (var dx = 0; dx < scale; dx++) {
            final i = (row + x * scale + dx) * 4;

            r += source[i];
            g += source[i + 1];
            b += source[i + 2];
            a += source[i + 3];
          }
        }

        final o = (y * width + x) * 4;

        target[o] = r ~/ blockPixels;
        target[o + 1] = g ~/ blockPixels;
        target[o + 2] = b ~/ blockPixels;
        target[o + 3] = a ~/ blockPixels;
      }
    }
  }
}
