// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamepad_input_mapper.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gamepadInputMapper)
final gamepadInputMapperProvider = GamepadInputMapperProvider._();

final class GamepadInputMapperProvider
    extends
        $FunctionalProvider<
          GamepadInputMapper,
          GamepadInputMapper,
          GamepadInputMapper
        >
    with $Provider<GamepadInputMapper> {
  GamepadInputMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamepadInputMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamepadInputMapperHash();

  @$internal
  @override
  $ProviderElement<GamepadInputMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamepadInputMapper create(Ref ref) {
    return gamepadInputMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamepadInputMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamepadInputMapper>(value),
    );
  }
}

String _$gamepadInputMapperHash() =>
    r'08e2ceb682b3a19e591cc0cf17974e08e6d1df82';
