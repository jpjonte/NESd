import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/latency_activity.dart';

void main() {
  late LatencyActivity activity;

  setUp(() => activity = LatencyActivity());

  tearDown(() => activity.dispose());

  test('starts without an activity', () {
    expect(activity.active, isFalse);
  });

  test('deactivating before activating is a no-op', () {
    activity.setActive(active: false);

    expect(activity.active, isFalse);
  });

  group('on macOS', () {
    test('activating holds an activity', () {
      activity.setActive(active: true);

      expect(activity.active, isTrue);
    });

    test('deactivating releases the activity', () {
      activity
        ..setActive(active: true)
        ..setActive(active: false);

      expect(activity.active, isFalse);
    });

    test('activating twice releases on a single deactivation', () {
      activity
        ..setActive(active: true)
        ..setActive(active: true)
        ..setActive(active: false);

      expect(activity.active, isFalse);
    });

    test('reactivating after a release holds an activity again', () {
      activity
        ..setActive(active: true)
        ..setActive(active: false)
        ..setActive(active: true);

      expect(activity.active, isTrue);
    });

    test('dispose releases a held activity', () {
      activity
        ..setActive(active: true)
        ..dispose();

      expect(activity.active, isFalse);
    });

    test('activating after dispose does nothing', () {
      activity
        ..dispose()
        ..setActive(active: true);

      expect(activity.active, isFalse);
    });
  }, skip: Platform.isMacOS ? null : 'macOS only');

  group('off macOS', () {
    test('activating never holds an activity', () {
      activity.setActive(active: true);

      expect(activity.active, isFalse);
    });
  }, skip: Platform.isMacOS ? 'non-macOS only' : null);
}
