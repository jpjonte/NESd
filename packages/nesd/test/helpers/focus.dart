import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

bool focusInside(WidgetTester tester, Finder ancestor) {
  final context = primaryFocus?.context;

  if (context == null || ancestor.evaluate().isEmpty) {
    return false;
  }

  return find
      .descendant(
        of: ancestor,
        matching: find.byElementPredicate((e) => identical(e, context)),
      )
      .evaluate()
      .isNotEmpty;
}

void focusInto(WidgetTester tester, Finder ancestor) {
  bool inside(FocusNode node) {
    final context = node.context;

    if (context == null) {
      return false;
    }

    return find
        .descendant(
          of: ancestor,
          matching: find.byElementPredicate((e) => identical(e, context)),
        )
        .evaluate()
        .isNotEmpty;
  }

  final nodes = tester.binding.focusManager.rootScope.traversalDescendants
      .where((node) => node is! FocusScopeNode && inside(node));

  expect(nodes, isNotEmpty, reason: 'no focusable node inside $ancestor');

  nodes.first.requestFocus();
}
