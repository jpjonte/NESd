import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/ui/log/log_buffer_provider.dart';

void main() {
  setUp(() {
    NesdLog.install(
      NesdLog(sinks: [LogBufferSink()], minimumLevel: LogLevel.debug),
    );
  });

  tearDown(() => NesdLog.install(NesdLog()));

  testWidgets('logging while the widget tree builds notifies listeners '
      'without throwing', (tester) async {
    var logged = false;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final records = ref.watch(logBufferProvider).records;

            return Builder(
              builder: (context) {
                if (!logged) {
                  logged = true;

                  NesdLog.instance.app.info('logged during build');
                }

                return Text(
                  '${records.length}',
                  textDirection: TextDirection.ltr,
                );
              },
            );
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
  });
}
