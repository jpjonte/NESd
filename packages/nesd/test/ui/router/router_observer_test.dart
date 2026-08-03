import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/router/router_observer.dart';

Route<void> route(String name) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name),
  pageBuilder: (_, _, _) => const SizedBox.shrink(),
);

void main() {
  late ProviderContainer container;
  late RouterObserver observer;

  setUp(() {
    container = ProviderContainer();

    // `@riverpod` providers auto-dispose, so hold a subscription for the
    // duration of the test.
    final subscription = container.listen(
      routerObserverProvider,
      (_, _) {},
      fireImmediately: true,
    );

    observer = container.read(routerObserverProvider.notifier);

    addTearDown(subscription.close);
    addTearDown(container.dispose);
  });

  // `_update` defers to a microtask, so let it run before asserting.
  Future<String?> currentRoute() async {
    await Future<void>.delayed(Duration.zero);

    return container.read(routerObserverProvider);
  }

  test('reports the pushed route', () async {
    observer
      ..didPush(route('MainRoute'), null)
      ..didChangeTop(route('MainRoute'), null);

    expect(await currentRoute(), 'MainRoute');
  });

  test('reports the route below the one that was popped', () async {
    final main = route('MainRoute');
    final filePicker = route('FilePickerRoute');

    observer
      ..didPush(filePicker, main)
      ..didChangeTop(filePicker, main)
      ..didPop(filePicker, main)
      ..didChangeTop(main, filePicker);

    expect(await currentRoute(), 'MainRoute');
  });

  test(
    'keeps reporting the top route when a route below it is popped',
    () async {
      final main = route('MainRoute');
      final filePicker = route('FilePickerRoute');
      final emulator = route('EmulatorRoute');

      // The file picker is pushed and then popped, but the emulator route is
      // pushed on top before the picker's exit transition finishes, so the
      // picker leaves the stack while it is no longer the topmost route, and
      // `didChangeTop` does not fire for it.
      observer
        ..didPush(filePicker, main)
        ..didChangeTop(filePicker, main)
        ..didPush(emulator, filePicker)
        ..didChangeTop(emulator, filePicker)
        ..didPop(filePicker, main);

      expect(await currentRoute(), 'EmulatorRoute');
    },
  );

  test(
    'keeps reporting the top route when a route below it is removed',
    () async {
      final main = route('MainRoute');
      final filePicker = route('FilePickerRoute');
      final emulator = route('EmulatorRoute');

      observer
        ..didPush(filePicker, main)
        ..didChangeTop(filePicker, main)
        ..didPush(emulator, filePicker)
        ..didChangeTop(emulator, filePicker)
        ..didRemove(filePicker, main);

      expect(await currentRoute(), 'EmulatorRoute');
    },
  );

  test(
    'keeps reporting the top route while a back gesture is in progress',
    () async {
      final main = route('MainRoute');
      final emulator = route('EmulatorRoute');

      observer
        ..didPush(emulator, main)
        ..didChangeTop(emulator, main)
        ..didStartUserGesture(emulator, main);

      expect(await currentRoute(), 'EmulatorRoute');
    },
  );
}
