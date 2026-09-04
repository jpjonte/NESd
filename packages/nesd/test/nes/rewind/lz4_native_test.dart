import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/rewind/lz4_native.dart';

void main() {
  final lz4 = Lz4.instance;

  test('compressBytes prefixes the uncompressed length', () {
    final data = Uint8List.fromList(List.generate(4096, (i) => i % 7));

    final block = lz4.compressBytes(data);

    expect(
      ByteData.sublistView(block).getUint32(0, Endian.little),
      data.length,
    );
    expect(block.length, lessThan(data.length));
  });

  test('round-trips through the Dart-list conveniences', () {
    final data = Uint8List.fromList(
      List.generate(50000, (i) => (i * 31) & 0xff),
    );

    expect(lz4.decompressBytes(lz4.compressBytes(data)), data);
  });

  test('round-trips through pointers into a caller-owned buffer', () {
    const size = 1024;
    final source = calloc<Uint8>(size);
    final target = calloc<Uint8>(size);

    addTearDown(() {
      calloc
        ..free(source)
        ..free(target);
    });

    for (var i = 0; i < size; i++) {
      source[i] = (i * 13) & 0xff;
    }

    final block = lz4.compressPointer(source, size);
    final written = lz4.decompressInto(block, target, size);

    expect(written, size);
    expect(target.asTypedList(size), source.asTypedList(size));
  });

  test('a corrupt block throws NesdException', () {
    final block = lz4.compressBytes(Uint8List.fromList(List.filled(300, 1)));

    for (var i = 4; i < block.length; i++) {
      block[i] = 0xff;
    }

    expect(() => lz4.decompressBytes(block), throwsA(isA<NesdException>()));
  });

  test('a truncated block throws NesdException', () {
    expect(
      () => lz4.decompressBytes(Uint8List(2)),
      throwsA(isA<NesdException>()),
    );
  });

  test('a block that does not fit its destination throws NesdException', () {
    final block = lz4.compressBytes(Uint8List(64));

    const size = 16;
    final dst = calloc<Uint8>(size);
    addTearDown(() => calloc.free(dst));

    expect(
      () => lz4.decompressInto(block, dst, size),
      throwsA(isA<NesdException>()),
    );
  });

  test('compressBytes round-trips empty input', () {
    expect(lz4.decompressBytes(lz4.compressBytes(Uint8List(0))), isEmpty);
  });

  test('compressBound is at least the input size', () {
    expect(lz4.compressBound(245760), greaterThanOrEqualTo(245760));
  });

  test('falls back to the bundle default library file name', () {
    final expected = switch (Platform.operatingSystem) {
      'macos' => 'eslz4-mac64.dylib',
      'linux' => 'eslz4-linux64.so',
      'windows' => 'eslz4-win64.dll',
      _ => throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      ),
    };

    expect(Lz4.defaultFileName, expected);
  });
}
