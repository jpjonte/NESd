// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cartridge_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cartridgeFactory)
final cartridgeFactoryProvider = CartridgeFactoryProvider._();

final class CartridgeFactoryProvider
    extends
        $FunctionalProvider<
          CartridgeFactory,
          CartridgeFactory,
          CartridgeFactory
        >
    with $Provider<CartridgeFactory> {
  CartridgeFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartridgeFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartridgeFactoryHash();

  @$internal
  @override
  $ProviderElement<CartridgeFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CartridgeFactory create(Ref ref) {
    return cartridgeFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartridgeFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartridgeFactory>(value),
    );
  }
}

String _$cartridgeFactoryHash() => r'ddd160cb67abc5c89cad415502e9687177364ea0';
