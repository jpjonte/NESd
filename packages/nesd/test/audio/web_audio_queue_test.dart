import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_audio/src/web_audio_queue.dart';

void main() {
  test('push fills up to capacity and short-writes past it', () {
    final queue = WebAudioQueue(capacity: 100);

    expect(queue.push(60), 60);
    expect(queue.push(60), 40);
    expect(queue.estimatedFill, 100);
    expect(queue.overruns, 1);
    expect(queue.push(10), 0);
    expect(queue.overruns, 2);
  });

  test('a report that already saw every push does not double-count', () {
    final queue = WebAudioQueue(capacity: 2400)
      ..push(800)
      ..report(fill: 800, underruns: 0, received: 800);

    expect(queue.estimatedFill, 800);
  });

  test('in-flight pushes the report has not seen are preserved', () {
    final queue = WebAudioQueue(capacity: 2400)
      ..push(800)
      ..report(fill: 0, underruns: 0, received: 0);

    expect(queue.estimatedFill, 800);
  });

  test('mixed case: consumed fill plus partially seen pushes', () {
    final queue = WebAudioQueue(capacity: 2400)
      ..push(800)
      ..push(400)
      ..report(fill: 750, underruns: 0, received: 800);

    expect(queue.estimatedFill, 1150);
  });

  test('underruns accumulate across reports', () {
    final queue = WebAudioQueue(capacity: 100)
      ..report(fill: 0, underruns: 2, received: 0)
      ..report(fill: 0, underruns: 3, received: 0);

    expect(queue.underruns, 5);
  });

  test('resetStats clears counters but not fill', () {
    final queue = WebAudioQueue(capacity: 100)
      ..push(150)
      ..report(fill: 50, underruns: 3, received: 100)
      ..resetStats();

    expect(queue.underruns, 0);
    expect(queue.overruns, 0);
    expect(queue.estimatedFill, 50);
  });

  test('reset zeroes the accounting', () {
    final queue = WebAudioQueue(capacity: 100)
      ..push(80)
      ..reset();

    expect(queue.estimatedFill, 0);

    queue
      ..push(50)
      ..report(fill: 50, underruns: 0, received: 50);

    expect(queue.estimatedFill, 50);
  });
}
