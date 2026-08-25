import 'dart:typed_data';

import 'package:es_compression/lz4.dart';

final _lz4 = Lz4Codec(level: -1);

Uint8List rewindCompress(Uint8List data) => _asUint8List(_lz4.encode(data));

Uint8List rewindDecompress(Uint8List data) => _asUint8List(_lz4.decode(data));

void setRewindCodecLibraryPath(String path) {
  Lz4Codec.libraryPath = path;
}

/// The current override, so hosts can forward it to worker isolates.
String? get rewindCodecLibraryPath => Lz4Codec.libraryPath;

Uint8List _asUint8List(List<int> list) =>
    list is Uint8List ? list : Uint8List.fromList(list);
