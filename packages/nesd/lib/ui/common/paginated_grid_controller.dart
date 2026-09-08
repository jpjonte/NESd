import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PaginatedGridController extends ChangeNotifier {
  int _page = 0;

  int _pageCount = 1;

  int get page => _page.clamp(0, _pageCount - 1);

  int get pageCount => _pageCount;

  set pageCount(int value) {
    _pageCount = max(1, value);
  }

  void previousPage() => _goTo(page - 1);

  void nextPage() => _goTo(page + 1);

  void _goTo(int target) {
    final clamped = target.clamp(0, _pageCount - 1);

    if (clamped == page) {
      return;
    }

    _page = clamped;

    notifyListeners();
  }
}

PaginatedGridController usePaginatedGridController() {
  final controller = useMemoized(PaginatedGridController.new);

  useEffect(() => controller.dispose, [controller]);

  return controller;
}
