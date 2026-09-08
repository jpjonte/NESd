import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:nesd/log/log.dart';

typedef _PointerFn = Pointer<Void> Function(Pointer<Utf8>);

typedef _MsgSend = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);

typedef _MsgSendString =
    Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Utf8>);

typedef _MsgSendActivity =
    Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int, Pointer<Void>);

typedef _MsgSendVoid =
    void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>);

typedef _PoolPush = Pointer<Void> Function();

typedef _PoolPop = void Function(Pointer<Void>);

typedef _Retain = Pointer<Void> Function(Pointer<Void>);

typedef _Release = void Function(Pointer<Void>);

class LatencyActivity {
  static const _options = 0xFF00FFFFFF;

  static const _reason = 'NESd emulation';

  bool _disposed = false;

  Pointer<Void> _token = nullptr;

  bool get active => _token != nullptr;

  void setActive({required bool active}) {
    if (active) {
      _begin();
    } else {
      _end();
    }
  }

  void dispose() {
    _end();

    _disposed = true;
  }

  void _begin() {
    if (_disposed || active) {
      return;
    }

    final objc = _ObjcRuntime.resolve();

    if (objc == null) {
      return;
    }

    final pool = objc.autoreleasePoolPush();

    try {
      final token = objc.beginActivity(_options, _reason);

      if (token == nullptr) {
        return;
      }

      _token = objc.retain(token);
    } finally {
      objc.autoreleasePoolPop(pool);
    }
  }

  void _end() {
    final token = _token;

    if (token == nullptr) {
      return;
    }

    _token = nullptr;

    _ObjcRuntime.resolve()
      ?..endActivity(token)
      ..release(token);
  }
}

class _ObjcRuntime {
  _ObjcRuntime._() {
    final process = DynamicLibrary.process();

    _getClass = process.lookupFunction<_PointerFn, _PointerFn>('objc_getClass');
    _registerName = process.lookupFunction<_PointerFn, _PointerFn>(
      'sel_registerName',
    );

    autoreleasePoolPush = process.lookupFunction<_PoolPush, _PoolPush>(
      'objc_autoreleasePoolPush',
    );
    autoreleasePoolPop = process
        .lookupFunction<Void Function(Pointer<Void>), _PoolPop>(
          'objc_autoreleasePoolPop',
        );
    retain = process.lookupFunction<_Retain, _Retain>('objc_retain');
    release = process.lookupFunction<Void Function(Pointer<Void>), _Release>(
      'objc_release',
    );

    final msgSend = process.lookupFunction<_MsgSend, _MsgSend>('objc_msgSend');

    _beginActivityMsg = process
        .lookupFunction<
          Pointer<Void> Function(
            Pointer<Void>,
            Pointer<Void>,
            Uint64,
            Pointer<Void>,
          ),
          _MsgSendActivity
        >('objc_msgSend');
    _endActivityMsg = process
        .lookupFunction<
          Void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>),
          _MsgSendVoid
        >('objc_msgSend');
    _stringMsg = process.lookupFunction<_MsgSendString, _MsgSendString>(
      'objc_msgSend',
    );

    _processInfo = msgSend(
      _lookupClass('NSProcessInfo'),
      _selector('processInfo'),
    );
    _beginActivitySelector = _selector('beginActivityWithOptions:reason:');
    _endActivitySelector = _selector('endActivity:');
    _stringClass = _lookupClass('NSString');
    _stringSelector = _selector('stringWithUTF8String:');
  }

  static bool _resolved = false;
  static _ObjcRuntime? _instance;

  static _ObjcRuntime? resolve() {
    if (_resolved) {
      return _instance;
    }

    _resolved = true;

    if (!Platform.isMacOS) {
      return null;
    }

    try {
      _instance = _ObjcRuntime._();
      // lookupFunction throws ArgumentError when a symbol is missing
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      log.emulator.warning('Latency-critical activity unavailable', error: e);
    }

    return _instance;
  }

  late final _PoolPush autoreleasePoolPush;
  late final _PoolPop autoreleasePoolPop;
  late final _Retain retain;
  late final _Release release;

  late final _PointerFn _getClass;
  late final _PointerFn _registerName;

  late final _MsgSendActivity _beginActivityMsg;
  late final _MsgSendVoid _endActivityMsg;
  late final _MsgSendString _stringMsg;

  late final Pointer<Void> _processInfo;
  late final Pointer<Void> _beginActivitySelector;
  late final Pointer<Void> _endActivitySelector;
  late final Pointer<Void> _stringClass;
  late final Pointer<Void> _stringSelector;

  Pointer<Void> beginActivity(int options, String reason) => _withUtf8(
    reason,
    (utf8) => _beginActivityMsg(
      _processInfo,
      _beginActivitySelector,
      options,
      _stringMsg(_stringClass, _stringSelector, utf8),
    ),
  );

  void endActivity(Pointer<Void> token) =>
      _endActivityMsg(_processInfo, _endActivitySelector, token);

  Pointer<Void> _lookupClass(String name) => _withUtf8(name, _getClass);

  Pointer<Void> _selector(String name) => _withUtf8(name, _registerName);

  Pointer<Void> _withUtf8(
    String value,
    Pointer<Void> Function(Pointer<Utf8>) action,
  ) {
    final utf8 = value.toNativeUtf8();

    try {
      return action(utf8);
    } finally {
      calloc.free(utf8);
    }
  }
}
