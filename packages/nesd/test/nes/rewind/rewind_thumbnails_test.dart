import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/rewind/rewind_thumbnails.dart';

Uint8List _source() {
  final pixels = Uint8List(8 * 4 * 4);

  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      final i = (y * 8 + x) * 4;

      pixels[i] = 255;
      pixels[i + 3] = 255;
    }
  }

  return pixels;
}

void main() {
  test('box-averages each 4x4 block', () {
    final thumbnails = RewindThumbnails(
      capacity: 4,
      sourceWidth: 8,
      sourceHeight: 4,
    )..add(0, _source());

    expect(thumbnails.width, 2);
    expect(thumbnails.height, 1);

    final pixels = thumbnails.snapshot().single.pixels;

    expect(pixels.sublist(0, 4), [255, 0, 0, 255]);
    expect(pixels.sublist(4, 8), [0, 0, 0, 0]);
  });

  test('averages a half-filled block to its mean', () {
    final source = Uint8List(4 * 4 * 4);

    for (var i = 0; i < 8; i++) {
      source[i * 4] = 200;
    }

    final thumbnails = RewindThumbnails(
      capacity: 2,
      sourceWidth: 4,
      sourceHeight: 4,
    )..add(0, source);

    expect(thumbnails.snapshot().single.pixels[0], 100);
  });

  test('evicts oldest and reports sequences oldest-first', () {
    final thumbnails = RewindThumbnails(
      capacity: 2,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 3; sequence++) {
      thumbnails.add(sequence, _source());
    }

    expect(thumbnails.length, 2);
    expect(thumbnails.snapshot().map((t) => t.sequence), [1, 2]);
  });

  test('reuses buffers instead of allocating per add', () {
    final thumbnails = RewindThumbnails(
      capacity: 2,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 2; sequence++) {
      thumbnails.add(sequence, _source());
    }

    final first = thumbnails.snapshot().first.pixels;

    for (var sequence = 2; sequence < 6; sequence++) {
      thumbnails.add(sequence, _source());
    }

    expect(
      thumbnails.snapshot().any((t) => identical(t.pixels, first)),
      isTrue,
    );
  });

  test('clear empties the ring', () {
    final thumbnails =
        RewindThumbnails(capacity: 2, sourceWidth: 8, sourceHeight: 4)
          ..add(0, _source())
          ..clear();

    expect(thumbnails.length, 0);
    expect(thumbnails.snapshot(), isEmpty);
  });

  test('truncateAfter drops entries above the cut', () {
    final thumbnails = RewindThumbnails(
      capacity: 5,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 5; sequence++) {
      thumbnails.add(sequence * 10, _source());
    }

    thumbnails.truncateAfter(25);

    expect(thumbnails.length, 3);
    expect(thumbnails.snapshot().map((t) => t.sequence), [0, 10, 20]);
  });

  test('truncateAfter keeps entries exactly at the cut', () {
    final thumbnails = RewindThumbnails(
      capacity: 3,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 3; sequence++) {
      thumbnails.add(sequence * 10, _source());
    }

    thumbnails.truncateAfter(20);

    expect(thumbnails.length, 3);
    expect(thumbnails.snapshot().map((t) => t.sequence), [0, 10, 20]);
  });

  test('truncateAfter on a wrapped ring only trims the newest end', () {
    final thumbnails = RewindThumbnails(
      capacity: 3,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 5; sequence++) {
      thumbnails.add(sequence * 10, _source());
    }

    thumbnails.truncateAfter(25);

    expect(thumbnails.length, 1);
    expect(thumbnails.snapshot().map((t) => t.sequence), [20]);
  });

  test('truncateAfter reuses buffers instead of reallocating', () {
    final thumbnails = RewindThumbnails(
      capacity: 3,
      sourceWidth: 8,
      sourceHeight: 4,
    );

    for (var sequence = 0; sequence < 3; sequence++) {
      thumbnails.add(sequence * 10, _source());
    }

    final droppedPixels = thumbnails.snapshot().last.pixels;

    thumbnails.truncateAfter(10);

    expect(thumbnails.length, 2);

    thumbnails.add(999, _source());

    expect(
      thumbnails.snapshot().any((t) => identical(t.pixels, droppedPixels)),
      isTrue,
    );
  });
}
