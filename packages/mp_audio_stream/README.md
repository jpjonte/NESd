
A Flutter plugin for multi-platform, simple audio stream playback with real-time generated audio data streams

## Features

- Continuously plays buffered audio data at 44.1kHz until the buffer is empty
- Supported format: float32 multi-channel
- Suppots all flutter platforms: Android, iOS, macOS, Linux, Windows, and Web platforms
  - Web platform implementaion relies on WebAudio and `AudioWorkletProcessor`
  - Other platforms utilize [miniaudio](https://github.com/mackron/miniaudio.git), an outstandig multi-platform audio library

## Getting started

```
flutter pub add mp_audio_stream
```

## Usage

```dart
import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

void main() async {
  final audioStream = getAudioStream();

  //default init params: {int bufferMilliSec = 3000,
  //                      int waitingBufferMilliSec = 100,
  //                      int channels = 1,
  //                      int sampleRate = 44100}
  audioStream.init(channels: 2); //Call this from Flutter's State.initState() method

  //For web platform, call this after user interaction
  audioStream.resume(); 

  // generating a stereo sine-wave PCM stream
  const rate = 44100;
  const freqL = 440;
  const freqR = 660;
  const dur = 10;

  Float32List samples = Float32List(rate);

  for (var t = 0; t < dur; t++) {
    int pos = 0;

    for (var i = 0; i < rate; i++) {
      samples[pos++] = math.sin(2 * math.pi * ((i * freqL) % rate) / rate);
      samples[pos++] = math.sin(2 * math.pi * ((i * freqR) % rate) / rate);

      if (pos == samples.length) {
        pos = 0;

        // playback the generated PCM stream
        audioStream.push(samples);
      }
    }
    if (t > 0) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  //Call this from Flutter's State.dispose()\
  audioStream.uninit(); 
}
```

For more API Documents, visit [pub.dev](https://pub.dev/packages/mp_audio_stream).

A runnable Flutter example application is at `/example/`.

# For developers

Update miniaudio submodule after `git clone`.

```
git submodule update --init
```
