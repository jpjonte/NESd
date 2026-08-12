import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer({
    required String settingsJson,
    FragmentProgramLoader? loader,
  }) {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn(settingsJson);
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (loader != null)
          fragmentProgramLoaderProvider.overrideWithValue(loader),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  test('a failing load marks the filter failed and deactivates it', () async {
    final container = buildContainer(
      settingsJson: '{"videoFilter":"crt"}',
      loader: (asset) async => throw Exception('no shader support'),
    )..listen(videoFilterActiveProvider, (_, _) {});

    expect(container.read(videoFilterActiveProvider), isTrue);

    container
        .read(videoFilterRegistryProvider.notifier)
        .ensureLoaded(VideoFilter.crt);

    await pumpEventQueue();

    final state = container.read(videoFilterRegistryProvider);

    expect(state.hasFailed(VideoFilter.crt), isTrue);
    expect(state.ready(VideoFilter.crt), isFalse);
    expect(container.read(videoFilterActiveProvider), isFalse);
  });

  test(
    'disposing the container mid-load does not surface an unhandled error',
    () async {
      final completer = Completer<ui.FragmentProgram>();

      final container = buildContainer(
        settingsJson: '{"videoFilter":"crt"}',
        loader: (asset) => completer.future,
      );

      container
          .read(videoFilterRegistryProvider.notifier)
          .ensureLoaded(VideoFilter.crt);

      container.dispose();

      completer.completeError(Exception('disposed mid-load'));

      await pumpEventQueue();
    },
  );

  test('the active provider is false when the filter is off', () {
    final container = buildContainer(settingsJson: '{}');

    expect(container.read(videoFilterActiveProvider), isFalse);
  });

  testWidgets('a successful load exposes a shader', (tester) async {
    await tester.runAsync(() async {
      final container = buildContainer(settingsJson: '{"videoFilter":"crt"}');

      container
          .read(videoFilterRegistryProvider.notifier)
          .ensureLoaded(VideoFilter.crt);

      for (
        var i = 0;
        i < 100 &&
            !container.read(videoFilterRegistryProvider).ready(VideoFilter.crt);
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final state = container.read(videoFilterRegistryProvider);

      expect(state.ready(VideoFilter.crt), isTrue);
      expect(state.shaders[VideoFilter.crt], isA<ui.FragmentShader>());
      expect(container.read(videoFilterActiveProvider), isTrue);
    });
  });
}
