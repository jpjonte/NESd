import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toaster.g.dart';

@riverpod
Toaster toaster(ToasterRef ref) {
  final toaster = Toaster(
    state: ref.watch(toastStateProvider.notifier),
  );

  ref.onDispose(toaster.dispose);

  return toaster;
}

class Toaster {
  Toaster({required this.state}) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _update();
    });
  }

  final ToastState state;

  late final Timer _timer;

  void dispose() {
    _timer.cancel();
  }

  void send(Toast toast) {
    state.add(toast);
  }

  void dismiss(Toast toast) {
    state.remove(toast);
  }

  void _update() {
    final top = state.top;

    if (top == null) {
      return;
    }

    final lifetime = switch (top.type) {
      ToastType.info => const Duration(seconds: 3),
      ToastType.warning => const Duration(seconds: 5),
      ToastType.error => const Duration(seconds: 8),
    };

    if (DateTime.now().difference(top.createdAt) > lifetime) {
      state.pop();
    }
  }
}

@riverpod
class ToastState extends _$ToastState {
  @override
  List<Toast> build() {
    return [];
  }

  List<Toast> get toasts => state;

  Toast? get top => state.firstOrNull;

  void add(Toast toast) {
    state = [...state, toast];
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

enum ToastType {
  info,
  warning,
  error,
}

class Toast {
  Toast({required this.type, required this.message});

  Toast.info(this.message) : type = ToastType.info;

  Toast.warning(this.message) : type = ToastType.warning;

  Toast.error(this.message) : type = ToastType.error;

  final String message;
  final ToastType type;
  final DateTime createdAt = DateTime.now();
}
