// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rom_downloader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(romFetcher)
final romFetcherProvider = RomFetcherProvider._();

final class RomFetcherProvider
    extends $FunctionalProvider<RomFetcher, RomFetcher, RomFetcher>
    with $Provider<RomFetcher> {
  RomFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romFetcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romFetcherHash();

  @$internal
  @override
  $ProviderElement<RomFetcher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RomFetcher create(Ref ref) {
    return romFetcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RomFetcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RomFetcher>(value),
    );
  }
}

String _$romFetcherHash() => r'f2a45475294546c111df1d8c78850264fa970e3c';

@ProviderFor(romDownloader)
final romDownloaderProvider = RomDownloaderProvider._();

final class RomDownloaderProvider
    extends $FunctionalProvider<RomDownloader, RomDownloader, RomDownloader>
    with $Provider<RomDownloader> {
  RomDownloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romDownloaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romDownloaderHash();

  @$internal
  @override
  $ProviderElement<RomDownloader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RomDownloader create(Ref ref) {
    return romDownloader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RomDownloader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RomDownloader>(value),
    );
  }
}

String _$romDownloaderHash() => r'6e464665b08c21cf5ab2c8efcf30e5c3d7341afc';
