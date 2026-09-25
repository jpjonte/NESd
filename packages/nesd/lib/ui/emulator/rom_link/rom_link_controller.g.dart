// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rom_link_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Starts ROMs from links and holds the running one until it is saved.
///
/// The state is the [UnsavedRom] while it runs; it drops once another ROM
/// runs or the game quits.

@ProviderFor(RomLinkController)
final romLinkControllerProvider = RomLinkControllerProvider._();

/// Starts ROMs from links and holds the running one until it is saved.
///
/// The state is the [UnsavedRom] while it runs; it drops once another ROM
/// runs or the game quits.
final class RomLinkControllerProvider
    extends $NotifierProvider<RomLinkController, UnsavedRom?> {
  /// Starts ROMs from links and holds the running one until it is saved.
  ///
  /// The state is the [UnsavedRom] while it runs; it drops once another ROM
  /// runs or the game quits.
  RomLinkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'romLinkControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$romLinkControllerHash();

  @$internal
  @override
  RomLinkController create() => RomLinkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnsavedRom? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnsavedRom?>(value),
    );
  }
}

String _$romLinkControllerHash() => r'0bb45bb8a9a74fca336b1e653689f6fa34a94063';

/// Starts ROMs from links and holds the running one until it is saved.
///
/// The state is the [UnsavedRom] while it runs; it drops once another ROM
/// runs or the game quits.

abstract class _$RomLinkController extends $Notifier<UnsavedRom?> {
  UnsavedRom? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UnsavedRom?, UnsavedRom?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UnsavedRom?, UnsavedRom?>,
              UnsavedRom?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
