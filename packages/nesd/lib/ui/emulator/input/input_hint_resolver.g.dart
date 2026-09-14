// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_hint_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inputHintResolver)
final inputHintResolverProvider = InputHintResolverProvider._();

final class InputHintResolverProvider
    extends
        $FunctionalProvider<
          InputHintResolver,
          InputHintResolver,
          InputHintResolver
        >
    with $Provider<InputHintResolver> {
  InputHintResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inputHintResolverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inputHintResolverHash();

  @$internal
  @override
  $ProviderElement<InputHintResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InputHintResolver create(Ref ref) {
    return inputHintResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InputHintResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InputHintResolver>(value),
    );
  }
}

String _$inputHintResolverHash() => r'f3465500dca423e3d495e00602f5575ee54e0dfd';
