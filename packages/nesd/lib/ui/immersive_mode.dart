import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Hides Android's system bars for the lifetime of the app.
///
/// The listener registers itself with the binding and stays active even if the
/// returned reference is discarded. The return value is only used in tests.
AppLifecycleListener? enableImmersiveMode() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }

  _hideSystemBars();

  // Android restores the bars when backgrounding, so reapply on resume
  return AppLifecycleListener(onResume: _hideSystemBars);
}

void _hideSystemBars() {
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
}
