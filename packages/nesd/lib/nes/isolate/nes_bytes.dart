/// Byte payloads crossing the worker boundary.
///
/// Call `materialize()` at most once. Only the native implementation
/// enforces it.
library;

export 'package:nesd/nes/isolate/nes_bytes_native.dart'
    if (dart.library.js_interop) 'package:nesd/nes/isolate/nes_bytes_web.dart';
