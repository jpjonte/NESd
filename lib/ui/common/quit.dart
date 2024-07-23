import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void quit() {
  if (kIsWeb) {
    return;
  }

  if (Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
    SystemNavigator.pop();
  } else {
    debugger();
    exit(0);
  }
}
