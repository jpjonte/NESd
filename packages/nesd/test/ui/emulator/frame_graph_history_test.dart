import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/frame_graph_history.dart';

void main() {
  test('records work as frame time minus sleep time', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000);

    expect(history.length, 1);
    expect(history.workAt(0), 12000);
    expect(history.sleepAt(0), 4000);
  });

  test('clamps work to zero when sleep exceeds the frame time', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 3000, sleepTimeMicroseconds: 5000);

    expect(history.workAt(0), 0);
  });

  test('keeps the most recent columns oldest first once it wraps', () {
    final history = FrameGraphHistory(capacity: 3);

    for (var i = 1; i <= 5; i++) {
      history.add(frameTimeMicroseconds: i * 1000, sleepTimeMicroseconds: 0);
    }

    expect(history.length, 3);
    expect(
      [for (var i = 0; i < history.length; i++) history.workAt(i)],
      [3000, 4000, 5000],
    );
  });

  test('clear empties the history', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000)
      ..clear();

    expect(history.length, 0);
  });

  test('notifies listeners when a frame is added', () {
    final history = FrameGraphHistory(capacity: 4);

    var notifications = 0;

    history
      ..addListener(() => notifications++)
      ..add(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000);

    expect(notifications, 1);
  });

  test('notifies listeners when cleared', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 16000, sleepTimeMicroseconds: 4000);

    var notifications = 0;

    history
      ..addListener(() => notifications++)
      ..clear();

    expect(notifications, 1);
  });
}
