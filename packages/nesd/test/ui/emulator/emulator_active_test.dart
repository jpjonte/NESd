import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();

    final subscription = container.listen(
      emulatorActiveProvider,
      (_, _) {},
      fireImmediately: true,
    );

    addTearDown(subscription.close);
    addTearDown(container.dispose);
  });

  void goTo(String? route) =>
      container.read(currentRouteProvider.notifier).update(route);

  test('is false before any route is reported', () {
    expect(container.read(emulatorActiveProvider), isFalse);
  });

  test('is true on the emulator route', () {
    goTo(EmulatorRoute.name);

    expect(container.read(emulatorActiveProvider), isTrue);
  });

  test('is false on the main menu', () {
    goTo(MainRoute.name);

    expect(container.read(emulatorActiveProvider), isFalse);
  });

  test('is false while the in-game menu covers the emulator', () {
    goTo(EmulatorRoute.name);
    goTo(MenuRoute.name);

    expect(container.read(emulatorActiveProvider), isFalse);
  });

  test('is false while an unnamed dialog route is on top', () {
    goTo(EmulatorRoute.name);
    goTo(null);

    expect(container.read(emulatorActiveProvider), isFalse);
  });

  test('still notifies a consumer whose own listeners are paused', () async {
    final seen = <bool>[];

    final consumerProvider = Provider.autoDispose<Object>((ref) {
      ref.listen(emulatorActiveProvider, (_, active) => seen.add(active));

      return Object();
    });

    final consumer = container.listen(consumerProvider, (_, _) {});

    addTearDown(consumer.close);

    consumer.pause();

    goTo(EmulatorRoute.name);
    goTo(MenuRoute.name);

    await pumpEventQueue();

    expect(seen, [true, false]);
  });
}
