// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debugger_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DebuggerStateNotifier)
final debuggerStateProvider = DebuggerStateNotifierProvider._();

final class DebuggerStateNotifierProvider
    extends $NotifierProvider<DebuggerStateNotifier, DebuggerState> {
  DebuggerStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debuggerStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debuggerStateNotifierHash();

  @$internal
  @override
  DebuggerStateNotifier create() => DebuggerStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DebuggerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DebuggerState>(value),
    );
  }
}

String _$debuggerStateNotifierHash() =>
    r'1c92f424cc51b9ee5aff4ad7789c6fe7a6fba228';

abstract class _$DebuggerStateNotifier extends $Notifier<DebuggerState> {
  DebuggerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DebuggerState, DebuggerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DebuggerState, DebuggerState>,
              DebuggerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
