import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:riverpod/riverpod.dart';

/// Whether the emulator screen is the one the user is looking at.
///
/// This gates two things: whether `ActionHandler` delivers in-game input, and
/// whether `NesController` lets the emulator run.
final emulatorActiveProvider = currentRouteProvider.select(
  (route) => route == EmulatorRoute.name,
);
