import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class BaseRobot {
  BaseRobot(this.tester);

  final WidgetTester tester;

  void expectOne(Finder finder) {
    expect(finder, findsOneWidget);
  }

  Future<void> go(Finder finder) async {
    await expectAndTap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> goAsync(Finder finder) async {
    await expectAndTap(finder);
    await fixAsync();
  }

  Future<void> goBack() async {
    await go(find.byType(BackButton).last);
  }

  Future<void> expectAndTap(Finder finder) async {
    expectOne(finder);
    await tester.tap(finder);
  }

  Future<void> expectSwitch(
    Finder finder, {
    required bool Function() getValue,
  }) async {
    final initialValue = getValue();

    expect(getValue(), equals(initialValue));

    await go(finder);

    expect(getValue(), equals(!initialValue));

    await go(finder);

    expect(getValue(), equals(initialValue));
  }

  Future<void> pumpFrames(Duration duration) async {
    await tester.pumpFrames(
      tester.widget(find.byType(ProviderScope)),
      duration,
    );
  }

  /// Runs both real async code and FakeAsync code.
  /// This way, image decoding can run and finish in the tests.
  Future<void> fixAsync() async {
    await tester.runAsync(
      () async => await Future.delayed(const Duration(milliseconds: 50)),
    );
    await pumpFrames(const Duration(milliseconds: 50));
  }

  /// Repeatedly drains real async work and fake-clock frames (see
  /// [fixAsync]) until [condition] is satisfied.
  ///
  /// Some fire-and-forget async chains (e.g. `unawaited(controller.stop())`
  /// triggered by a button tap) now perform real file IO before they settle.
  /// A single [fixAsync] round trip isn't always enough real time to drain
  /// such a chain, so poll for the condition instead of guessing a fixed
  /// pump count.
  Future<void> waitUntil(
    bool Function() condition, {
    int maxAttempts = 20,
  }) async {
    for (var attempt = 0; attempt < maxAttempts && !condition(); attempt++) {
      await fixAsync();
    }

    expect(
      condition(),
      isTrue,
      reason: 'condition not met after $maxAttempts fixAsync cycles',
    );
  }
}
