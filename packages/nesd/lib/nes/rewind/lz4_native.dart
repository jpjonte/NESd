import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nesd/exception/nesd_exception.dart';

typedef _CompressBound = int Function(int inputSize);
typedef _Compress =
    int Function(
      Pointer<Uint8> src,
      Pointer<Uint8> dst,
      int srcSize,
      int dstCapacity,
    );
typedef _Decompress =
    int Function(
      Pointer<Uint8> src,
      Pointer<Uint8> dst,
      int compressedSize,
      int dstCapacity,
    );

class Lz4 {
  Lz4._(DynamicLibrary library)
    : _compressBound = library
          .lookupFunction<Int32 Function(Int32 inputSize), _CompressBound>(
            'LZ4_compressBound',
          ),
      _compress = library
          .lookupFunction<
            Int32 Function(
              Pointer<Uint8> src,
              Pointer<Uint8> dst,
              Int32 srcSize,
              Int32 dstCapacity,
            ),
            _Compress
          >('LZ4_compress_default'),
      _decompress = library
          .lookupFunction<
            Int32 Function(
              Pointer<Uint8> src,
              Pointer<Uint8> dst,
              Int32 compressedSize,
              Int32 dstCapacity,
            ),
            _Decompress
          >('LZ4_decompress_safe');

  static const int prefixLength = 4;

  static String? libraryPath;

  static final Lz4 instance = Lz4._(
    DynamicLibrary.open(libraryPath ?? defaultFileName),
  );

  @visibleForTesting
  static String get defaultFileName {
    final bitness = sizeOf<IntPtr>() == 4 ? '32' : '64';

    return switch (Platform.operatingSystem) {
      'android' => 'libeslz4-android$bitness.so',
      'macos' => 'eslz4-mac$bitness.dylib',
      'linux' => 'eslz4-linux$bitness.so',
      'windows' => 'eslz4-win$bitness.dll',
      _ => throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      ),
    };
  }

  final _CompressBound _compressBound;
  final _Compress _compress;
  final _Decompress _decompress;

  Pointer<Uint8> _input = nullptr;
  int _inputCapacity = 0;

  Pointer<Uint8> _output = nullptr;
  int _outputCapacity = 0;

  int compressBound(int size) => _compressBound(size);

  Uint8List compressPointer(Pointer<Uint8> src, int size) {
    final bound = compressBound(size);

    _ensureOutput(bound);

    final written = _compress(src, _output, size, bound);

    if (written <= 0) {
      throw NesdException('LZ4 compression failed');
    }

    final block = Uint8List(prefixLength + written);

    ByteData.sublistView(block).setUint32(0, size, Endian.little);
    block.setRange(prefixLength, block.length, _output.asTypedList(written));

    return block;
  }

  int decompressInto(Uint8List block, Pointer<Uint8> dst, int dstCapacity) {
    if (block.length < prefixLength) {
      throw NesdException('LZ4 block is truncated');
    }

    final length = ByteData.sublistView(block).getUint32(0, Endian.little);
    final compressedSize = block.length - prefixLength;

    if (length > dstCapacity) {
      throw NesdException('LZ4 block does not fit its destination');
    }

    _ensureInput(compressedSize);

    _input
        .asTypedList(compressedSize)
        .setAll(0, Uint8List.sublistView(block, prefixLength));

    final written = _decompress(_input, dst, compressedSize, dstCapacity);

    if (written != length) {
      throw NesdException('LZ4 block is corrupt');
    }

    return written;
  }

  Uint8List compressBytes(Uint8List data) {
    _ensureInput(data.length);

    _input.asTypedList(data.length).setAll(0, data);

    return compressPointer(_input, data.length);
  }

  Uint8List decompressBytes(Uint8List block) {
    if (block.length < prefixLength) {
      throw NesdException('LZ4 block is truncated');
    }

    final length = ByteData.sublistView(block).getUint32(0, Endian.little);

    _ensureOutput(length);

    decompressInto(block, _output, length);

    return Uint8List.fromList(_output.asTypedList(length));
  }

  void _ensureInput(int size) {
    if (size <= _inputCapacity) {
      return;
    }

    if (_input != nullptr) {
      calloc.free(_input);
    }

    final capacity = max(size, 1);

    _input = calloc<Uint8>(capacity);
    _inputCapacity = capacity;
  }

  void _ensureOutput(int size) {
    if (size <= _outputCapacity) {
      return;
    }

    if (_output != nullptr) {
      calloc.free(_output);
    }

    final capacity = max(size, 1);

    _output = calloc<Uint8>(capacity);
    _outputCapacity = capacity;
  }
}
