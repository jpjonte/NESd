import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

const _fileHash = 'f11e0000000000000000000000000000000000ff';
const _romHash = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsController controller;

  setUp(() {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    controller = container.read(settingsControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('breakpoints keyed by the old file hash move to the content '
      'hash', () {
    final breakpoints = [Breakpoint(0x8000)];

    controller
      ..setBreakpoints(_fileHash, breakpoints)
      ..adoptBreakpoints(legacyKey: _fileHash, romHash: _romHash);

    expect(controller.breakpoints[_romHash], breakpoints);
    expect(controller.breakpoints.containsKey(_fileHash), isFalse);
  });

  test('breakpoints already on the content hash win', () {
    final legacy = [Breakpoint(0x8000)];
    final current = [Breakpoint(0xc000)];

    controller
      ..setBreakpoints(_fileHash, legacy)
      ..setBreakpoints(_romHash, current)
      ..adoptBreakpoints(legacyKey: _fileHash, romHash: _romHash);

    expect(controller.breakpoints[_romHash], current);
    expect(controller.breakpoints.containsKey(_fileHash), isFalse);
  });

  test('nothing stored under the old key leaves settings alone', () {
    final current = [Breakpoint(0xc000)];

    controller
      ..setBreakpoints(_romHash, current)
      ..adoptBreakpoints(legacyKey: _fileHash, romHash: _romHash);

    expect(controller.breakpoints, {_romHash: current});
  });

  test('other ROMs keep their breakpoints', () {
    final mine = [Breakpoint(0x8000)];
    final theirs = [Breakpoint(0x9000)];

    controller
      ..setBreakpoints(_fileHash, mine)
      ..setBreakpoints('another-rom', theirs)
      ..adoptBreakpoints(legacyKey: _fileHash, romHash: _romHash);

    expect(controller.breakpoints['another-rom'], theirs);
  });

  test('adopting onto the same key keeps the breakpoints', () {
    final breakpoints = [Breakpoint(0x8000)];

    controller
      ..setBreakpoints(_romHash, breakpoints)
      ..adoptBreakpoints(legacyKey: _romHash, romHash: _romHash);

    expect(controller.breakpoints[_romHash], breakpoints);
  });
}
