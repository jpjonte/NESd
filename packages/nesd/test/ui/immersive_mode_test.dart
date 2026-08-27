import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/immersive_mode.dart';

void main() {
  late List<Object?> requestedModes;

  setUp(() {
    requestedModes = [];
  });

  Future<void> interceptSystemUiModeRequests(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
          requestedModes.add(call.arguments);
        }

        return null;
      },
    );

    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  testWidgets('hides the system bars on Android', (tester) async {
    await interceptSystemUiModeRequests(tester);

    final listener = enableImmersiveMode();

    addTearDown(() => listener?.dispose());

    await tester.pump();

    expect(requestedModes, ['SystemUiMode.immersiveSticky']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('re-hides the system bars when the app resumes', (tester) async {
    await interceptSystemUiModeRequests(tester);

    final listener = enableImmersiveMode();

    addTearDown(() => listener?.dispose());

    await tester.pump();

    requestedModes.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pump();

    expect(requestedModes, ['SystemUiMode.immersiveSticky']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('does nothing on other platforms', (tester) async {
    await interceptSystemUiModeRequests(tester);

    final listener = enableImmersiveMode();

    expect(listener, isNull);

    await tester.pump();

    expect(requestedModes, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
