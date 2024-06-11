import 'dart:math';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nes/audio/audio_buffer.dart';

class AudioOutput {
  AudioOutput() {
    _audioStream
      ..init(
        bufferMilliSec: 40,
        waitingBufferMilliSec: 20,
        sampleRate: 48000,
      )
      ..resume();
  }

  late final _audioStream = getAudioStream();

  final _audioBuffer = AudioBuffer(9600);

  double _volume = 1.0;

  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  void processSamples(Float32List samples) {
    final volumeApplied =
        Float32List.fromList(samples.map((s) => s * _volume).toList());

    final writeSize = _audioBuffer.write(volumeApplied);

    if (writeSize < volumeApplied.length) {
      print(
        'audio prebuffer full, wrote $writeSize/${volumeApplied.length}',
      );
    }

    _flushSamples();
  }

  void _flushSamples() {
    final currentSize = _audioStream.getBufferFillSize();
    final bufferSize = _audioStream.getBufferSize();
    final remainingBufferSize = bufferSize - currentSize;
    final bufferedSize = _audioBuffer.current;

    if (currentSize + bufferedSize < bufferSize / 3) {
      print(
        'waiting for buffer to fill: buffered $bufferedSize,'
        ' audio buffer $currentSize / $bufferSize',
      );

      return;
    }

    if (remainingBufferSize == 0) {
      _audioBuffer.clear(); // drop samples to catch up

      print('audio output buffer full');

      return;
    }

    final flushSize = min(remainingBufferSize, bufferedSize);

    if (flushSize == 0) {
      print('r $remainingBufferSize b $bufferedSize -> not flushing samples');

      return;
    }

    final samples = _audioBuffer.read(flushSize);

    _audioStream.push(samples);
  }
}
