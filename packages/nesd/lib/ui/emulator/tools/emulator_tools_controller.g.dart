// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emulator_tools_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which debug tools are currently open.
///
/// A facade over [SettingsController]: the open set lives in the settings
/// so it persists, and this is the single seam every host — docked,
/// compact, and the windowed one in #244 — talks to.

@ProviderFor(EmulatorToolsController)
final emulatorToolsControllerProvider = EmulatorToolsControllerProvider._();

/// Which debug tools are currently open.
///
/// A facade over [SettingsController]: the open set lives in the settings
/// so it persists, and this is the single seam every host — docked,
/// compact, and the windowed one in #244 — talks to.
final class EmulatorToolsControllerProvider
    extends $NotifierProvider<EmulatorToolsController, Set<EmulatorTool>> {
  /// Which debug tools are currently open.
  ///
  /// A facade over [SettingsController]: the open set lives in the settings
  /// so it persists, and this is the single seam every host — docked,
  /// compact, and the windowed one in #244 — talks to.
  EmulatorToolsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emulatorToolsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emulatorToolsControllerHash();

  @$internal
  @override
  EmulatorToolsController create() => EmulatorToolsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<EmulatorTool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<EmulatorTool>>(value),
    );
  }
}

String _$emulatorToolsControllerHash() =>
    r'9aac0a4aba81347a8d179762adfd9b0358816fea';

/// Which debug tools are currently open.
///
/// A facade over [SettingsController]: the open set lives in the settings
/// so it persists, and this is the single seam every host — docked,
/// compact, and the windowed one in #244 — talks to.

abstract class _$EmulatorToolsController extends $Notifier<Set<EmulatorTool>> {
  Set<EmulatorTool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<EmulatorTool>, Set<EmulatorTool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<EmulatorTool>, Set<EmulatorTool>>,
              Set<EmulatorTool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
