import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

void focusFirstDescendant(FocusNode node) {
  node.descendants.firstWhereOrNull((d) => d.canRequestFocus)?.requestFocus();
}
