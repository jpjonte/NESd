// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_bus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventBus)
final eventBusProvider = EventBusProvider._();

final class EventBusProvider
    extends $FunctionalProvider<EventBus, EventBus, EventBus>
    with $Provider<EventBus> {
  EventBusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventBusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventBusHash();

  @$internal
  @override
  $ProviderElement<EventBus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventBus create(Ref ref) {
    return eventBus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventBus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventBus>(value),
    );
  }
}

String _$eventBusHash() => r'cd86b01c7c650bfe197fb00aa7b9c43b204872a0';
