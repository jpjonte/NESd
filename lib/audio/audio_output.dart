import 'dart:math';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/audio_buffer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_output.g.dart';

@riverpod
AudioOutput audioOutput(AudioOutputRef ref) {
  final audioOutput = AudioOutput();

  ref.onDispose(audioOutput.dispose);

  final settingsSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.volume),
    (_, volume) => audioOutput.volume = volume,
    fireImmediately: true,
  );

  ref.onDispose(settingsSubscription.close);

  return audioOutput;
}

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

  void dispose() {
    _audioStream.uninit();
  }

  void processSamples(Float32List samples) {
    final volumeApplied =
        Float32List.fromList(samples.map((s) => s * _volume).toList());

    _audioBuffer.write(volumeApplied);

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
    final bufferedSize = _audioStream.getBufferFilledSize();
    final bufferSize = _audioStream.getBufferSize();
    final remainingBufferSize = bufferSize - bufferedSize;
    final preBufferedSize = _audioBuffer.current;
    final preBufferSize = _audioBuffer.size;

    if (_buffering) {
      if (preBufferedSize < preBufferSize * 0.5) {
        return;
      }

      _buffering = false;
    } else if (bufferedSize == 0) {
      _buffering = true;

      return;
    }

    if (remainingBufferSize == 0) {
      _audioBuffer.clear(); // drop samples to catch up

      return;
    }

    final flushSize = min(remainingBufferSize, preBufferedSize);

    if (flushSize == 0) {
      return;
    }

    final samples = _audioBuffer.read(flushSize);

    _audioStream.push(samples);
  }
}
