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
