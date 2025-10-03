// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_input_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(keyboardInputHandler)
const keyboardInputHandlerProvider = KeyboardInputHandlerProvider._();

final class KeyboardInputHandlerProvider
    extends
        $FunctionalProvider<
          KeyboardInputHandler,
          KeyboardInputHandler,
          KeyboardInputHandler
        >
    with $Provider<KeyboardInputHandler> {
  const KeyboardInputHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyboardInputHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyboardInputHandlerHash();

  @$internal
  @override
  $ProviderElement<KeyboardInputHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KeyboardInputHandler create(Ref ref) {
    return keyboardInputHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyboardInputHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyboardInputHandler>(value),
    );
  }
}

String _$keyboardInputHandlerHash() =>
    r'ce5ba8ce2a61208d3d3c9facae172a4af23afde1';
