// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamepad_input_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'14f12dc25162ee895a856af0ae857db1cac74efb';
