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
          DisplayFrameController,
          DisplayFrameController,
          DisplayFrameController
        >
    with $Provider<DisplayFrameController> {
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
  $ProviderElement<DisplayFrameController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DisplayFrameController create(Ref ref) {
    return displayFrameController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisplayFrameController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisplayFrameController>(value),
    );
  }
}

String _$displayFrameControllerHash() =>
    r'f9780433279abdb7dd1676dab810dd7acecec7bd';
