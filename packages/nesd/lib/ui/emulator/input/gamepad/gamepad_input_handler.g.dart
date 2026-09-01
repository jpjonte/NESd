// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamepad_input_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gamepadSlotRegistry)
final gamepadSlotRegistryProvider = GamepadSlotRegistryProvider._();

final class GamepadSlotRegistryProvider
    extends
        $FunctionalProvider<
          GamepadSlotRegistry,
          GamepadSlotRegistry,
          GamepadSlotRegistry
        >
    with $Provider<GamepadSlotRegistry> {
  GamepadSlotRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamepadSlotRegistryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamepadSlotRegistryHash();

  @$internal
  @override
  $ProviderElement<GamepadSlotRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamepadSlotRegistry create(Ref ref) {
    return gamepadSlotRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamepadSlotRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamepadSlotRegistry>(value),
    );
  }
}

String _$gamepadSlotRegistryHash() =>
    r'86b223b035e378575f2ab3480fb475a39544ac64';

@ProviderFor(gamepadInputHandler)
final gamepadInputHandlerProvider = GamepadInputHandlerProvider._();

final class GamepadInputHandlerProvider
    extends
        $FunctionalProvider<
          GamepadInputHandler,
          GamepadInputHandler,
          GamepadInputHandler
        >
    with $Provider<GamepadInputHandler> {
  GamepadInputHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamepadInputHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamepadInputHandlerHash();

  @$internal
  @override
  $ProviderElement<GamepadInputHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamepadInputHandler create(Ref ref) {
    return gamepadInputHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamepadInputHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamepadInputHandler>(value),
    );
  }
}

String _$gamepadInputHandlerHash() =>
    r'749c20fb6187cf8c2b659add89828438572d8193';
