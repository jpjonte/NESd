import 'dart:typed_data';

import 'nesd_texture_platform_interface.dart';

class NesdTexture {
  NesdTexture._({
    required this.textureId,
    required this.width,
    required this.height,
  });

  final int textureId;
  final int width;
  final int height;

  static Future<NesdTexture> create({
    required int width,
    required int height,
  }) async {
    final textureId = await NesdTexturePlatform.instance.createTexture(
      width: width,
      height: height,
    );

    return NesdTexture._(textureId: textureId, width: width, height: height);
  }

  Future<void> update(Uint8List pixels) async {
    await NesdTexturePlatform.instance.updateTexture(
      textureId: textureId,
      width: width,
      height: height,
      pixels: pixels,
    );
  }

  Future<void> dispose() async {
    await NesdTexturePlatform.instance.disposeTexture(textureId: textureId);
  }
}
