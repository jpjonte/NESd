import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../mp_audio_stream.dart';

typedef _MAInitFunc = Int Function(Int64, Int64, Int64, Int64);
typedef _MAInit = int Function(int, int, int, int);

typedef _MAPushFunc = Int Function(Pointer<Float>, Int64);
typedef _MAPush = int Function(Pointer<Float>, int);

typedef _MAVoidFunc = Void Function();
typedef _MAVoid = void Function();

typedef _MAIntFunc = Int Function();
typedef _MAInt = int Function();

/// Contol class for AudioStream on "not" web platform. Use `getAudioStream()` to get its instance.
class AudioStreamImpl implements AudioStream {
  late _MAPush _pushFfi;
  late _MAVoid _uninitFfi;
  late _MAInt _statExhaustCountFfi;
  late _MAInt _statFullCountFfi;
  late _MAVoid _statResetFfi;
  late _MAInt _getBufferSizeFfi;
  late _MAInt _getBufferFilledSizeFfi;

  @override
  int init({
    int bufferMilliSec = 3000,
    int waitingBufferMilliSec = 100,
    int channels = 1,
    int sampleRate = 44100,
  }) {
    final dynLib = (Platform.isLinux || Platform.isAndroid)
        ? DynamicLibrary.open("libmp_audio_stream.so")
        : Platform.isWindows
        ? DynamicLibrary.open("mp_audio_stream.dll")
        : (Platform.isMacOS || Platform.isIOS)
        ? DynamicLibrary.executable()
        : DynamicLibrary.executable();

    final initFfi = dynLib
        .lookup<NativeFunction<_MAInitFunc>>("ma_stream_init")
        .asFunction<_MAInit>();

    _pushFfi = dynLib
        .lookup<NativeFunction<_MAPushFunc>>("ma_stream_push")
        .asFunction<_MAPush>();

    _uninitFfi = dynLib
        .lookup<NativeFunction<_MAVoidFunc>>("ma_stream_uninit")
        .asFunction<_MAVoid>();

    _statExhaustCountFfi = dynLib
        .lookup<NativeFunction<_MAIntFunc>>("ma_stream_stat_exhaust_count")
        .asFunction<_MAInt>();

    _statFullCountFfi = dynLib
        .lookup<NativeFunction<_MAIntFunc>>("ma_stream_stat_full_count")
        .asFunction<_MAInt>();

    _statResetFfi = dynLib
        .lookup<NativeFunction<_MAVoidFunc>>("ma_stream_stat_reset")
        .asFunction<_MAVoid>();

    _getBufferSizeFfi = dynLib
        .lookup<NativeFunction<_MAIntFunc>>("ma_buffer_size")
        .asFunction<_MAInt>();

    _getBufferFilledSizeFfi = dynLib
        .lookup<NativeFunction<_MAIntFunc>>("ma_buffer_filled_size")
        .asFunction<_MAInt>();

    return initFfi(
      channels * bufferMilliSec * sampleRate ~/ 1000,
      channels * waitingBufferMilliSec * sampleRate ~/ 1000,
      channels,
      sampleRate,
    );
  }

  @override
  int push(Float32List buf) {
    final ffiBuf = calloc<Float>(buf.length);
    for (int i = 0; i < buf.length; i++) {
      ffiBuf[i] = buf[i];
    }
    final result = _pushFfi(ffiBuf, buf.length);
    calloc.free(ffiBuf);
    return result;
  }

  @override
  AudioStreamStat stat() {
    return AudioStreamStat(
      full: _statFullCountFfi(),
      exhaust: _statExhaustCountFfi(),
    );
  }

  @override
  void uninit() {
    _uninitFfi();
  }

  @override
  void resume() {}

  @override
  void resetStat() {
    _statResetFfi();
  }

  @override
  int getBufferSize() {
    return _getBufferSizeFfi();
  }

  @override
  int getBufferFilledSize() {
    return _getBufferFilledSizeFfi();
  }
}
