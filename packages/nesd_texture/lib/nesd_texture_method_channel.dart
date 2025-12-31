import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nesd_texture_platform_interface.dart';

/// An implementation of [NesdTexturePlatform] that uses method channels.
class MethodChannelNesdTexture extends NesdTexturePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nesd_texture');

  @override
  Future<int> createTexture({required int width, required int height}) async {
    final textureId = await methodChannel.invokeMethod<int>(
      'createTexture',
      <String, Object?>{'width': width, 'height': height},
    );

    if (textureId == null) {
      throw PlatformException(
        code: 'invalid-texture',
        message: 'Native layer returned null texture id',
      );
    }

    return textureId;
  }

  @override
  Future<void> updateTexture({
    required int textureId,
    required int width,
    required int height,
    required int length,
    Uint8List? pixels,
    int? pixelPointer,
  }) async {
    await methodChannel.invokeMethod<void>('updateTexture', <String, Object?>{
      'textureId': textureId,
      'width': width,
      'height': height,
      'length': length,
      if (pixels != null) 'pixels': pixels,
      if (pixelPointer != null) 'pixelPointer': pixelPointer,
    });
  }

  @override
  Future<void> disposeTexture({required int textureId}) async {
    await methodChannel.invokeMethod<void>('disposeTexture', <String, Object?>{
      'textureId': textureId,
    });
  }
}
