import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_texture/nesd_texture_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNesdTexture platform = MethodChannelNesdTexture();
  const MethodChannel channel = MethodChannel('nesd_texture');

  test('createTexture forwards to channel', () async {
    const textureId = 7;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'createTexture');
          expect(methodCall.arguments, <String, Object?>{
            'width': 4,
            'height': 4,
          });

          return textureId;
        });

    expect(await platform.createTexture(width: 4, height: 4), textureId);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
