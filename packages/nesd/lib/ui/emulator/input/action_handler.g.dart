// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(actionStream)
final actionStreamProvider = ActionStreamProvider._();

final class ActionStreamProvider
    extends $FunctionalProvider<ActionStream, ActionStream, ActionStream>
    with $Provider<ActionStream> {
  ActionStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionStreamHash();

  @$internal
  @override
  $ProviderElement<ActionStream> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActionStream create(Ref ref) {
    return actionStream(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActionStream value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActionStream>(value),
    );
  }
}

String _$actionStreamHash() => r'639cbedd5a9e63c4d1539f80b28dde3f51eb3c45';

@ProviderFor(actionHandler)
final actionHandlerProvider = ActionHandlerProvider._();

final class ActionHandlerProvider
    extends $FunctionalProvider<ActionHandler, ActionHandler, ActionHandler>
    with $Provider<ActionHandler> {
  ActionHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionHandlerHash();

  @$internal
  @override
  $ProviderElement<ActionHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActionHandler create(Ref ref) {
    return actionHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActionHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActionHandler>(value),
    );
  }
}

String _$actionHandlerHash() => r'fedc5dc3214776cc7e171f6009f466e6d97ec98b';
