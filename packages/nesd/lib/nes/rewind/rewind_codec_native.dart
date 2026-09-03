import 'dart:typed_data';

import 'package:nesd/nes/rewind/lz4_native.dart';

Uint8List rewindCompress(Uint8List data) => Lz4.instance.compressBytes(data);

Uint8List rewindDecompress(Uint8List data) =>
    Lz4.instance.decompressBytes(data);

void setRewindCodecLibraryPath(String path) {
  Lz4.libraryPath = path;
}

/// The current override, so hosts can forward it to worker isolates.
String? get rewindCodecLibraryPath => Lz4.libraryPath;
