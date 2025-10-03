// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binder_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BinderStateNotifier)
const binderStateProvider = BinderStateNotifierFamily._();

final class BinderStateNotifierProvider
    extends $NotifierProvider<BinderStateNotifier, BinderState> {
  const BinderStateNotifierProvider._({
    required BinderStateNotifierFamily super.from,
    required InputAction super.argument,
  }) : super(
         retry: null,
         name: r'binderStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$binderStateNotifierHash();

  @override
  String toString() {
    return r'binderStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BinderStateNotifier create() => BinderStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BinderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BinderState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BinderStateNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$binderStateNotifierHash() =>
    r'027109c0744a948f497bfff2f31f419e88849203';

final class BinderStateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BinderStateNotifier,
          BinderState,
          BinderState,
          BinderState,
          InputAction
        > {
  const BinderStateNotifierFamily._()
    : super(
        retry: null,
        name: r'binderStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BinderStateNotifierProvider call(InputAction action) =>
      BinderStateNotifierProvider._(argument: action, from: this);

  @override
  String toString() => r'binderStateProvider';
}

abstract class _$BinderStateNotifier extends $Notifier<BinderState> {
  late final _$args = ref.$arg as InputAction;
  InputAction get action => _$args;

  BinderState build(InputAction action);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<BinderState, BinderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BinderState, BinderState>,
              BinderState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
