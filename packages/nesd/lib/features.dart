import 'package:flutter/foundation.dart';

/// Compile-time capability flags, const so disabled features aren't compiled.
abstract final class Features {
  /// Rewind compresses states with es_compression's LZ4, which is FFI-only.
  static const bool rewind = !kIsWeb;

  /// The debug tools are desktop-only for now.
  static const bool debugger = !kIsWeb;

  /// The fragment-shader filters are not wired up for the web renderer yet.
  static const bool videoFilters = !kIsWeb;

  /// The GPU renderer uploads frames via native texture pointers.
  static const bool gpuRenderer = !kIsWeb;

  /// PCM dumps write to local files via dart:io.
  static const bool pcmTools = !kIsWeb;
}
