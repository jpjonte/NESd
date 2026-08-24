import 'dart:typed_data';

// LZ4 compression is FFI-only, so rewind is disabled on web.
// Throw here so we can be sure it wasn't silently enabled.
Uint8List rewindCompress(Uint8List data) =>
    throw UnsupportedError('rewind compression is not available on web');

Uint8List rewindDecompress(Uint8List data) =>
    throw UnsupportedError('rewind compression is not available on web');

void setRewindCodecLibraryPath(String path) {}

String? get rewindCodecLibraryPath => null;
