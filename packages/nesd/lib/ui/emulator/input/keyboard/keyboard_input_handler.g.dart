// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_input_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(keyboardInputHandler)
final keyboardInputHandlerProvider = KeyboardInputHandlerProvider._();

final class KeyboardInputHandlerProvider
    extends
        $FunctionalProvider<
          KeyboardInputHandler,
          KeyboardInputHandler,
          KeyboardInputHandler
        >
    with $Provider<KeyboardInputHandler> {
  KeyboardInputHandlerProvider._()
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
    r'cb2bfa13cbd5ccf762b0ac0c5a5e5a788d87c202';
