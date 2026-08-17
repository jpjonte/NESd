// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(displayFrameController)
final displayFrameControllerProvider = DisplayFrameControllerProvider._();

final class DisplayFrameControllerProvider
    extends
        $FunctionalProvider<
          Raw<DisplayFrameController>,
          Raw<DisplayFrameController>,
          Raw<DisplayFrameController>
        >
    with $Provider<Raw<DisplayFrameController>> {
  DisplayFrameControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displayFrameControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displayFrameControllerHash();

  @$internal
  @override
  $ProviderElement<Raw<DisplayFrameController>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<DisplayFrameController> create(Ref ref) {
    return displayFrameController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<DisplayFrameController> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<DisplayFrameController>>(value),
    );
  }
}

String _$displayFrameControllerHash() =>
    r'9c506644dc2427f6fde5d8c9a674a0e16010fb71';
