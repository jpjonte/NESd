/// All methods must be called from the isolate that opened the stream.
/// The OS audio callback communicates only through the native SPSC ring.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:nesd_audio/src/nesd_audio_backend.dart';
import 'package:nesd_audio/src/nesd_audio_state.dart';

typedef _OpenNative = Pointer<Void> Function(Int32, Int32, Int32, Int32, Int32);
typedef _Open = Pointer<Void> Function(int, int, int, int, int);

typedef _PushNative = Int32 Function(Pointer<Void>, Pointer<Float>, Int32);
typedef _Push = int Function(Pointer<Void>, Pointer<Float>, int);

typedef _VoidFnNative = Void Function(Pointer<Void>);
typedef _VoidFn = void Function(Pointer<Void>);

typedef _Int32FnNative = Int32 Function(Pointer<Void>);
typedef _Int32Fn = int Function(Pointer<Void>);

typedef _Uint32FnNative = Uint32 Function(Pointer<Void>);

class NesdAudio implements NesdAudioBackend {
  NesdAudio._(this._handle, this._bindings);

  /// Opens a playback stream of f32 samples.
  ///
  /// [bufferSamples] is the ring capacity. After an underrun the stream
  /// emits silence until the ring refills to the largest device read
  /// seen plus [recoverSamples] of margin (capped at capacity).
  /// [nullDevice] selects a timer-driven fake device that consumes
  /// samples in real time without touching audio hardware.
  factory NesdAudio.open({
    required int sampleRate,
    required int channels,
    required int bufferSamples,
    required int recoverSamples,
    bool nullDevice = false,
  }) {
    final bindings = _Bindings(_load());

    final handle = bindings.open(
      sampleRate,
      channels,
      bufferSamples,
      recoverSamples,
      nullDevice ? _flagNullDevice : 0,
    );

    if (handle == nullptr) {
      throw StateError('Failed to open the nesd_audio stream');
    }

    return NesdAudio._(handle, bindings);
  }

  /// Overrides where the native library is loaded from. Per-isolate:
  /// hosts must forward it to worker isolates. Null in production (the
  /// plugin bundles the library).
  static String? libraryPath;

  static const _flagNullDevice = 1;

  final Pointer<Void> _handle;
  final _Bindings _bindings;

  Pointer<Float> _pushBuffer = nullptr;
  int _pushBufferCapacity = 0;

  @override
  int get capacity => _bindings.capacity(_handle);

  @override
  int get filled => _bindings.filled(_handle);

  @override
  int get underruns => _bindings.underruns(_handle);

  @override
  int get overruns => _bindings.overruns(_handle);

  @override
  int get popMax => _bindings.popMax(_handle);

  @override
  int get restarts => _bindings.restarts(_handle);

  @override
  NesdAudioState get state => NesdAudioState.values[_bindings.state(_handle)];

  @override
  int push(Float32List samples) {
    if (samples.isEmpty) {
      return 0;
    }

    if (_pushBufferCapacity < samples.length) {
      if (_pushBuffer != nullptr) {
        calloc.free(_pushBuffer);
      }

      _pushBuffer = calloc<Float>(samples.length);
      _pushBufferCapacity = samples.length;
    }

    _pushBuffer.asTypedList(samples.length).setAll(0, samples);

    return _bindings.push(_handle, _pushBuffer, samples.length);
  }

  // The native ring holds at most ~50 ms and drains in real time, so stale
  // samples vanish on their own.
  @override
  void reset() {}

  @override
  void resetStats() => _bindings.resetStats(_handle);

  @override
  void close() {
    _bindings.close(_handle);

    if (_pushBuffer != nullptr) {
      calloc.free(_pushBuffer);
      _pushBuffer = nullptr;
      _pushBufferCapacity = 0;
    }
  }

  static DynamicLibrary _load() {
    if (libraryPath case final path?) {
      return DynamicLibrary.open(path);
    }

    if (Platform.isWindows) {
      return DynamicLibrary.open('nesd_audio.dll');
    }

    if (Platform.isMacOS) {
      return DynamicLibrary.open('nesd_audio.framework/nesd_audio');
    }

    return DynamicLibrary.open('libnesd_audio.so');
  }
}

class _Bindings {
  _Bindings(DynamicLibrary library)
    : open = library
          .lookup<NativeFunction<_OpenNative>>('nesd_audio_open')
          .asFunction(),
      close = library
          .lookup<NativeFunction<_VoidFnNative>>('nesd_audio_close')
          .asFunction(),
      push = library
          .lookup<NativeFunction<_PushNative>>('nesd_audio_push')
          .asFunction(),
      capacity = library
          .lookup<NativeFunction<_Int32FnNative>>('nesd_audio_capacity')
          .asFunction(),
      filled = library
          .lookup<NativeFunction<_Int32FnNative>>('nesd_audio_filled')
          .asFunction(),
      state = library
          .lookup<NativeFunction<_Int32FnNative>>('nesd_audio_state')
          .asFunction(),
      underruns = library
          .lookup<NativeFunction<_Uint32FnNative>>('nesd_audio_underruns')
          .asFunction(),
      overruns = library
          .lookup<NativeFunction<_Uint32FnNative>>('nesd_audio_overruns')
          .asFunction(),
      popMax = library
          .lookup<NativeFunction<_Uint32FnNative>>('nesd_audio_pop_max')
          .asFunction(),
      restarts = library
          .lookup<NativeFunction<_Uint32FnNative>>('nesd_audio_restarts')
          .asFunction(),
      resetStats = library
          .lookup<NativeFunction<_VoidFnNative>>('nesd_audio_reset_stats')
          .asFunction();

  final _Open open;
  final _VoidFn close;
  final _Push push;
  final _Int32Fn capacity;
  final _Int32Fn filled;
  final _Int32Fn state;
  final _Int32Fn underruns;
  final _Int32Fn overruns;
  final _Int32Fn popMax;
  final _Int32Fn restarts;
  final _VoidFn resetStats;
}
