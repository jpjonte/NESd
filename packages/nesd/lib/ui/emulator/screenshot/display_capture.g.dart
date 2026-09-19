// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_capture.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(displayCapture)
final displayCaptureProvider = DisplayCaptureProvider._();

final class DisplayCaptureProvider
    extends $FunctionalProvider<DisplayCapture, DisplayCapture, DisplayCapture>
    with $Provider<DisplayCapture> {
  DisplayCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displayCaptureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displayCaptureHash();

  @$internal
  @override
  $ProviderElement<DisplayCapture> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DisplayCapture create(Ref ref) {
    return displayCapture(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisplayCapture value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisplayCapture>(value),
    );
  }
}

String _$displayCaptureHash() => r'f461b44da50588788bcd68c9f914ee345e219146';
