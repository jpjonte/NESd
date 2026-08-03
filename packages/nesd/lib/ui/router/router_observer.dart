import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_observer.g.dart';

@riverpod
class RouterObserver extends _$RouterObserver implements NavigatorObserver {
  @override
  String? build() => null;

  // `didChangeTop` is the only callback whose route is guaranteed to be the one
  // on screen, and the navigator fires it for every change of the topmost
  // route.
  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) =>
      _update(topRoute);

  @override
  void didPush(Route route, Route? previousRoute) {}

  @override
  void didPop(Route route, Route? previousRoute) {}

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {}

  @override
  void didRemove(Route route, Route? previousRoute) {}

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {}

  @override
  void didStopUserGesture() {}

  @override
  NavigatorState? get navigator => null;

  void _update(Route? route) =>
      scheduleMicrotask(() => state = route?.settings.name);
}
