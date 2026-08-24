import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/frame_source.dart';

void main() {
  test('addFrame uses inline pixels when present', () {
    final sent = <NesCommand>[];
    final source = RemoteFrameSource(sendCommand: sent.add);
    final pixels = Uint8List(256 * 240 * 4)..[0] = 42;

    source.addFrame(
      FrameEvent(
        frameHandle: 7,
        pixels: InlineFramePixels(bytes: pixels),
        width: 256,
        height: 240,
        frameTimeMicroseconds: 0,
        sleepTimeMicroseconds: 0,
        frame: 1,
        rewindSize: 0,
      ),
    );

    final frame = source.takeFrame();

    expect(frame, isNotNull);
    expect(frame!.bytes.first, 42);
    expect(frame.id, 7);
    expect(frame.pixelPointer, isNull);

    source.releaseFrame(frame);

    expect(sent.whereType<ReleaseFrameCommand>().single.frameHandle, 7);
  });
}
