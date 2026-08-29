import 'dart:async';

import 'package:flutter/widgets.dart';

const logoAsset = 'assets/logo.png';

Future<void> precacheLogo() {
  final completer = Completer<void>();
  final stream = const AssetImage(logoAsset).resolve(ImageConfiguration.empty);

  late final ImageStreamListener listener;

  void finish() {
    stream.removeListener(listener);

    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  listener = ImageStreamListener(
    (image, synchronousCall) => finish(),
    onError: (error, stackTrace) => finish(),
  );

  stream.addListener(listener);

  return completer.future;
}
