import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_observer.g.dart';

@riverpod
class RouterObserver extends _$RouterObserver implements NavigatorObserver {
  @override
  String? build() => null;

  @override
  void didPush(Route route, Route? previousRoute) => _update(route);

  @override
  void didPop(Route route, Route? previousRoute) => _update(route);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _update(newRoute);

  @override
  void didRemove(Route route, Route? previousRoute) => _update(route);

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) =>
      _update(topRoute);

  @override
  void didStartUserGesture(Route route, Route? previousRoute) => _update(route);

  @override
  void didStopUserGesture() {}

  @override
  NavigatorState? get navigator => null;

  void _update(Route? route) =>
      scheduleMicrotask(() => state = route?.settings.name);
}
