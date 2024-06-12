import 'dart:math';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nes/audio/audio_buffer.dart';

class AudioOutput {
  AudioOutput() {
    _init();
  }

  late final _audioStream = getAudioStream();

  final _audioBuffer = AudioBuffer(2400); // 50 ms

  var _buffering = false;

  double _volume = 1.0;

  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  void reset() {
    _audioStream.uninit();

    _audioBuffer.clear();

    _buffering = false;

    _init();
  }

  void processSamples(Float32List samples) {
    final volumeApplied =
        Float32List.fromList(samples.map((s) => s * _volume).toList());

    final writeSize = _audioBuffer.write(volumeApplied);

    if (writeSize < volumeApplied.length) {
      print(
        'audio prebuffer full (${_audioBuffer.size}),'
        ' wrote $writeSize/${volumeApplied.length}',
      );
    }

    _flushSamples();
  }

  void _init() {
    _audioStream
      ..init(
        bufferMilliSec: 50,
        waitingBufferMilliSec: 20,
        sampleRate: 48000,
      )
      ..resume();
  }

  void _flushSamples() {
    final bufferedSize = _audioStream.getBufferFillSize();
    final bufferSize = _audioStream.getBufferSize();
    final remainingBufferSize = bufferSize - bufferedSize;
    final preBufferedSize = _audioBuffer.current;
    final preBufferSize = _audioBuffer.size;

    if (_buffering) {
      if (preBufferedSize < preBufferSize * 0.5) {
        print(
          'waiting for prebuffer to fill:'
          ' buffered $preBufferedSize / $preBufferSize',
        );

        return;
      }

      print('audio prebuffer filled, resuming');

      _buffering = false;
    } else if (bufferedSize == 0) {
      print('audio output buffer empty, buffering');

      _buffering = true;

      return;
    }

    if (remainingBufferSize == 0) {
      _audioBuffer.clear(); // drop samples to catch up

      print('audio output buffer full');

      return;
    }

    final flushSize = min(remainingBufferSize, preBufferedSize);

    if (flushSize == 0) {
      print('b $preBufferedSize -> not flushing samples');

      return;
    }

    final samples = _audioBuffer.read(flushSize);

    _audioStream.push(samples);
  }
}
