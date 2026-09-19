// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(screenshotController)
final screenshotControllerProvider = ScreenshotControllerProvider._();

final class ScreenshotControllerProvider
    extends
        $FunctionalProvider<
          ScreenshotController,
          ScreenshotController,
          ScreenshotController
        >
    with $Provider<ScreenshotController> {
  ScreenshotControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotControllerHash();

  @$internal
  @override
  $ProviderElement<ScreenshotController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScreenshotController create(Ref ref) {
    return screenshotController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenshotController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenshotController>(value),
    );
  }
}

String _$screenshotControllerHash() =>
    r'6c7f9700a20455bc586808c8e98bc8db513d5800';
