// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emulator_tools_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmulatorToolsController)
final emulatorToolsControllerProvider = EmulatorToolsControllerProvider._();

final class EmulatorToolsControllerProvider
    extends $NotifierProvider<EmulatorToolsController, Set<EmulatorTool>> {
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
    r'f02bb9c395c93bd1229e2a14bec5f97c5d917eac';

abstract class _$EmulatorToolsController extends $Notifier<Set<EmulatorTool>> {
  Set<EmulatorTool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<EmulatorTool>, Set<EmulatorTool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<EmulatorTool>, Set<EmulatorTool>>,
              Set<EmulatorTool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
