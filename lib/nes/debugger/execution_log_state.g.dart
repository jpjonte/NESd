// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_log_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExecutionLogStateNotifier)
final executionLogStateProvider = ExecutionLogStateNotifierProvider._();

final class ExecutionLogStateNotifierProvider
    extends $NotifierProvider<ExecutionLogStateNotifier, ExecutionLogState> {
  ExecutionLogStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'executionLogStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$executionLogStateNotifierHash();

  @$internal
  @override
  ExecutionLogStateNotifier create() => ExecutionLogStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExecutionLogState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExecutionLogState>(value),
    );
  }
}

String _$executionLogStateNotifierHash() =>
    r'9bf0de82a51511726f0191c0f3a1f44d63e14a81';

abstract class _$ExecutionLogStateNotifier
    extends $Notifier<ExecutionLogState> {
  ExecutionLogState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExecutionLogState, ExecutionLogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExecutionLogState, ExecutionLogState>,
              ExecutionLogState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
