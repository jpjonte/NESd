// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(screenshotWriter)
final screenshotWriterProvider = ScreenshotWriterProvider._();

final class ScreenshotWriterProvider
    extends
        $FunctionalProvider<
          ScreenshotWriter,
          ScreenshotWriter,
          ScreenshotWriter
        >
    with $Provider<ScreenshotWriter> {
  ScreenshotWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotWriterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotWriterHash();

  @$internal
  @override
  $ProviderElement<ScreenshotWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScreenshotWriter create(Ref ref) {
    return screenshotWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenshotWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenshotWriter>(value),
    );
  }
}

String _$screenshotWriterHash() => r'9e2532ec035810c7d252b927786e97ea0e1ac675';
