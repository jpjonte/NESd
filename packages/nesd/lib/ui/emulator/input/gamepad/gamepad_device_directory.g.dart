// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamepad_device_directory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gamepadDeviceDirectory)
final gamepadDeviceDirectoryProvider = GamepadDeviceDirectoryProvider._();

final class GamepadDeviceDirectoryProvider
    extends
        $FunctionalProvider<
          GamepadDeviceDirectory,
          GamepadDeviceDirectory,
          GamepadDeviceDirectory
        >
    with $Provider<GamepadDeviceDirectory> {
  GamepadDeviceDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamepadDeviceDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamepadDeviceDirectoryHash();

  @$internal
  @override
  $ProviderElement<GamepadDeviceDirectory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamepadDeviceDirectory create(Ref ref) {
    return gamepadDeviceDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamepadDeviceDirectory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamepadDeviceDirectory>(value),
    );
  }
}

String _$gamepadDeviceDirectoryHash() =>
    r'a2504ef27d6f38658b5e519006f2d347203d58ac';
