// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(binderController)
const binderControllerProvider = BinderControllerFamily._();

final class BinderControllerProvider
    extends
        $FunctionalProvider<
          BinderController,
          BinderController,
          BinderController
        >
    with $Provider<BinderController> {
  const BinderControllerProvider._({
    required BinderControllerFamily super.from,
    required InputAction super.argument,
  }) : super(
         retry: null,
         name: r'binderControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$binderControllerHash();

  @override
  String toString() {
    return r'binderControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<BinderController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BinderController create(Ref ref) {
    final argument = this.argument as InputAction;
    return binderController(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BinderController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BinderController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BinderControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$binderControllerHash() => r'681df25cb9b4b5848f9196c8fb6c7ec6441a978c';

final class BinderControllerFamily extends $Family
    with $FunctionalFamilyOverride<BinderController, InputAction> {
  const BinderControllerFamily._()
    : super(
        retry: null,
        name: r'binderControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BinderControllerProvider call(InputAction action) =>
      BinderControllerProvider._(argument: action, from: this);

  @override
  String toString() => r'binderControllerProvider';
}
