import 'dart:async';

import 'package:web/web.dart' as web;

const _splashId = 'splash';
const _dismissedClass = 'dismissed';

// same as the CSS transition in `web/index.html`
const _fadeDuration = Duration(milliseconds: 250);

/// fade out the web splash screen
void dismissSplash() {
  final splash = web.document.getElementById(_splashId);

  if (splash == null) {
    return;
  }

  splash.classList.add(_dismissedClass);

  // wait for the fade to finish, then remove
  Timer(_fadeDuration, () => splash.remove());
}
