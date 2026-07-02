import 'dart:isolate';

class NesIsolateConfig {
  const NesIsolateConfig({
    required this.hostPort,
    this.lz4LibraryPath,
    this.disableAudio = false,
  });

  final SendPort hostPort;

  /// Path to the LZ4 dynamic library. `Lz4Codec.libraryPath` is a
  /// per-isolate static, so tests (which configure it in
  /// flutter_test_config.dart) must forward it to the spawned isolate.
  /// Null in production builds (es_compression resolves bundled libs).
  final String? lz4LibraryPath;

  /// When true, the worker uses `NullAudioStream` instead of the real
  /// platform audio backend. On macOS/iOS `mp_audio_stream` resolves its
  /// FFI symbols via `DynamicLibrary.executable()`, which under
  /// `flutter test` has no miniaudio symbols, so real audio init throws.
  /// Tests set this; production callers leave it false.
  final bool disableAudio;
}
