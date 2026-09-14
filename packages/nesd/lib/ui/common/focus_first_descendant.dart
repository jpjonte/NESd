import 'package:flutter/widgets.dart';

void focusFirstDescendant(FocusNode node) {
  node.traversalDescendants.firstOrNull?.requestFocus();
}
