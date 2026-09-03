import 'package:flutter/foundation.dart';

/// Compile-time capability flags, const so disabled features aren't compiled.
abstract final class Features {
  /// Rewind compresses states with the bundled LZ4 library, which is
  /// FFI-only.
  static const bool rewind = !kIsWeb;

  /// The debug tools are desktop-only for now.
  static const bool debugger = !kIsWeb;

  /// On the web the filters use the CPU renderer.
  /// GPU path stays gated by `ImageFilter.isShaderFilterSupported`.
  static const bool videoFilters = true;

  /// The GPU renderer uploads frames via native texture pointers.
  static const bool gpuRenderer = !kIsWeb;

  /// PCM dumps write to local files via dart:io.
  static const bool pcmTools = !kIsWeb;
}
