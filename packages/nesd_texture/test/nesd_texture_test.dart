import 'package:flutter_test/flutter_test.dart';
import 'package:nesd_texture/nesd_texture_platform_interface.dart';
import 'package:nesd_texture/nesd_texture_method_channel.dart';

void main() {
  final NesdTexturePlatform initialPlatform = NesdTexturePlatform.instance;

  test('$MethodChannelNesdTexture is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNesdTexture>());
  });
}
