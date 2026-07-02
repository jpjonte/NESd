import 'dart:isolate';

class NesIsolateConfig {
  const NesIsolateConfig({required this.hostPort, this.lz4LibraryPath});

  final SendPort hostPort;

  /// Path to the LZ4 dynamic library. `Lz4Codec.libraryPath` is a
  /// per-isolate static, so tests (which configure it in
  /// flutter_test_config.dart) must forward it to the spawned isolate.
  /// Null in production builds (es_compression resolves bundled libs).
  final String? lz4LibraryPath;
}
