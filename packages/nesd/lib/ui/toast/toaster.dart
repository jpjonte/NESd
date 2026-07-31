import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toaster.g.dart';

@riverpod
Toaster toaster(Ref ref) {
  final toaster = Toaster(state: ref.watch(toastStateProvider.notifier));

  ref.onDispose(toaster.dispose);

  return toaster;
}

class Toaster {
  Toaster({required this.state});

  final ToastState state;

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
  }

  void send(Toast toast) {
    state.add(toast);

    _scheduleExpiry();
  }

  void dismiss(Toast toast) {
    state.remove(toast);

    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _timer?.cancel();
    _timer = null;

    final top = state.top;

    if (top == null) {
      return;
    }

    final elapsed = DateTime.now().difference(top.createdAt);
    final remaining = _lifetime(top) - elapsed;

    if (remaining <= Duration.zero) {
      _onExpiry();

      return;
    }

    _timer = Timer(remaining, _onExpiry);
  }

  void _onExpiry() {
    state.pop();
    _scheduleExpiry();
  }

  Duration _lifetime(Toast toast) => switch (toast.type) {
    ToastType.info => const Duration(seconds: 3),
    ToastType.warning => const Duration(seconds: 5),
    ToastType.error => const Duration(seconds: 8),
  };
}

@riverpod
class ToastState extends _$ToastState {
  @override
  List<Toast> build() {
    return [];
  }

  List<Toast> get toasts => state;

  Toast? get top => state.firstOrNull;

  static const maxLength = 5;

  void add(Toast toast) {
    final duplicate = state.any(
      (t) => t.type == toast.type && t.message == toast.message,
    );

    if (duplicate) {
      return;
    }

    final toasts = [...state, toast];

    state = toasts.length > maxLength
        ? toasts.sublist(toasts.length - maxLength)
        : toasts;
  }

  void pop() {
    state = state.sublist(1);
  }

  void remove(Toast toast) {
    state = [
      for (final t in state)
        if (t != toast) t,
    ];
  }

  void clear() {
    state = [];
  }
}

enum ToastType { info, warning, error }

class Toast {
  Toast({required this.type, required String message})
    : message = _stripStackTrace(message);

  Toast.info(String message) : this(type: ToastType.info, message: message);

  Toast.warning(String message)
    : this(type: ToastType.warning, message: message);

  Toast.error(String message) : this(type: ToastType.error, message: message);

  final String message;
  final ToastType type;
  final DateTime createdAt = DateTime.now();
}

final _stackFrame = RegExp(r'^\s*(#\d+\s|<asynchronous suspension>)');

String _stripStackTrace(String message) {
  final lines = message.split('\n');

  final kept = lines.where((line) => !_stackFrame.hasMatch(line));

  return kept.join('\n').trimRight();
}
