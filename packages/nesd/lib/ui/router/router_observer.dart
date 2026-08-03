import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_observer.g.dart';

/// The name of the topmost route, or null when the topmost route is unnamed
/// (`showDialog` pushes unnamed routes, so an open dialog reads as null).
@riverpod
class CurrentRoute extends _$CurrentRoute {
  @override
  String? build() => null;

  // can't use a setter to change the state from outside
  // ignore: use_setters_to_change_properties
  void update(String? name) => state = name;
}

@riverpod
NesdRouterObserver nesdRouterObserver(Ref ref) =>
    NesdRouterObserver(ref.watch(currentRouteProvider.notifier));

/// Publishes the topmost route to [currentRouteProvider].
///
/// `didChangeTop` is the only navigator callback whose route is guaranteed to
/// be the one on screen, and the navigator fires it for every change of the
/// topmost route.
class NesdRouterObserver extends NavigatorObserver {
  NesdRouterObserver(this._currentRoute);

  final CurrentRoute _currentRoute;

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    scheduleMicrotask(() => _currentRoute.update(topRoute.settings.name));
  }
}
