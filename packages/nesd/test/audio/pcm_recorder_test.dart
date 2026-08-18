import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nesd_pcm');
    path = '${dir.path}/audio.pcm';
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('buffers writes until a chunk fills', () {
    final recorder = PcmRecorder(path: path, chunkSamples: 4)
      ..add(Float32List.fromList([1.0, 2.0, 3.0]));

    expect(File(path).lengthSync(), 0);

    recorder.add(Float32List.fromList([4.0, 5.0]));

    expect(File(path).lengthSync(), 16); // one full 4-sample chunk

    recorder.close();
  });

  test('close flushes the partial chunk', () {
    PcmRecorder(path: path, chunkSamples: 4)
      ..add(Float32List.fromList([1.0, 2.0]))
      ..close();

    expect(File(path).lengthSync(), 8);
  });

  test('samples round-trip as float32 bytes', () {
    PcmRecorder(path: path, chunkSamples: 2)
      ..add(Float32List.fromList([0.25, -0.5, 1.0]))
      ..close();

    final data = File(path).readAsBytesSync();
    final floats = data.buffer.asFloat32List();

    expect(floats, [0.25, -0.5, 1.0]);
  });

  test('write failure logs once, disables the recorder, never throws', () {
    final recorder = PcmRecorder(path: path, chunkSamples: 2)
      ..add(Float32List.fromList([1.0, 2.0]))
      ..close();

    final logged = <LogRecord>[];

    NesdLog.install(NesdLog(sinks: [_RecordingSink(logged)]));

    addTearDown(() async {
      await NesdLog.instance.close();

      NesdLog.install(NesdLog());
    });

    recorder
      ..add(Float32List.fromList([3.0, 4.0]))
      ..add(Float32List.fromList([5.0, 6.0]));

    expect(logged, hasLength(1));
    expect(logged.single.message, startsWith('NESD_PCM_ERROR'));

    // Only the pre-close chunk made it to disk; the recorder is dead.
    expect(File(path).lengthSync(), 8);

    // close() after failure must also not throw.
    recorder.close();
  });
}
