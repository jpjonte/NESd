import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;
  late ProviderContainer container;
  late SettingsController controller;
  late List<LogRecord> logged;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');

    container =
        ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          )
          ..listen(settingsControllerProvider, (_, _) {})
          ..listen(toastStateProvider, (_, _) {});

    controller = container.read(settingsControllerProvider.notifier);

    logged = [];

    NesdLog.install(
      NesdLog(sinks: [_RecordingSink(logged)], minimumLevel: LogLevel.debug),
    );

    addTearDown(() async {
      await NesdLog.instance.close();

      NesdLog.install(NesdLog());
    });
  });

  tearDown(() => container.dispose());

  test('a rejected settings write shows a warning toast', () async {
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);

    controller.showDebugOverlay = true;

    await pumpEventQueue();

    expect(controller.showDebugOverlay, isTrue);

    final toasts = container.read(toastStateProvider);

    expect(toasts, hasLength(1));
    expect(toasts.single.type, ToastType.warning);
    expect(toasts.single.message, contains('Failed to save settings'));
  });

  test('a throwing settings write shows a warning toast and logs the '
      'error', () async {
    when(
      () => prefs.setString(any(), any()),
    ).thenAnswer((_) async => throw Exception('disk full'));

    controller.showDebugOverlay = true;

    await pumpEventQueue();

    expect(controller.showDebugOverlay, isTrue);

    final toasts = container.read(toastStateProvider);

    expect(toasts, hasLength(1));
    expect(toasts.single.type, ToastType.warning);
    expect(toasts.single.message, contains('Failed to save settings'));

    expect(logged, hasLength(1));
    expect(logged.single.message, 'Failed to save settings');
    expect(logged.single.error, contains('disk full'));
  });
}
