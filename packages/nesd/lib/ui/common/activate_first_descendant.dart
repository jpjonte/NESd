import 'dart:async';

import 'package:flutter/material.dart';

void activateFirstDescendant(FocusNode focusNode) {
  final childContext = focusNode.descendants.firstOrNull?.context;

  if (childContext == null) {
    return;
  }

  const intent = ActivateIntent();

  final flutterAction = Actions.maybeFind(childContext, intent: intent);

  if (flutterAction == null) {
    return;
  }

  scheduleMicrotask(() {
    if (!childContext.mounted) {
      return;
    }

    Actions.of(childContext).invokeAction(flutterAction, intent);
  });
}
