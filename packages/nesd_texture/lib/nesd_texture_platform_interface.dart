import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nesd_texture_method_channel.dart';

abstract class NesdTexturePlatform extends PlatformInterface {
  /// Constructs a NesdTexturePlatform.
  NesdTexturePlatform() : super(token: _token);

  static final Object _token = Object();

  static NesdTexturePlatform _instance = MethodChannelNesdTexture();

  /// The default instance of [NesdTexturePlatform] to use.
  ///
  /// Defaults to [MethodChannelNesdTexture].
  static NesdTexturePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NesdTexturePlatform] when
  /// they register themselves.
  static set instance(NesdTexturePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int> createTexture({required int width, required int height}) {
    throw UnimplementedError('createTexture() has not been implemented.');
  }

  Future<void> updateTexture({
    required int textureId,
    required int width,
    required int height,
    required int length,
    Uint8List? pixels,
    int? pixelPointer,
  }) {
    throw UnimplementedError('updateTexture() has not been implemented.');
  }

  Future<void> disposeTexture({required int textureId}) {
    throw UnimplementedError('disposeTexture() has not been implemented.');
  }
}
