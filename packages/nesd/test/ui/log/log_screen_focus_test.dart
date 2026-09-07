import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/log/log_screen.dart';
import 'package:nesd/ui/router/router.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

Future<Robot> _openLog(WidgetTester tester) async {
  final r = Robot(tester);

  await r.pumpApp();

  r.container.read(routerProvider).navigate(const LogRoute());

  await tester.pumpAndSettle();

  return r;
}

void main() {
  setUp(() {
    NesdLog.install(
      NesdLog(sinks: [LogBufferSink()], minimumLevel: LogLevel.debug),
    );
  });

  tearDown(() => NesdLog.install(NesdLog()));

  testWidgets('the app bar actions stay reachable from the body', (
    tester,
  ) async {
    final r = await _openLog(tester);

    focusInto(tester, find.byKey(LogScreen.levelFilterKey));
    await tester.pump();

    r.sendInputAction(inputUp);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AppBar)), isTrue);
    expect(focusInside(tester, find.byType(BackButton)), isFalse);
  });
}
