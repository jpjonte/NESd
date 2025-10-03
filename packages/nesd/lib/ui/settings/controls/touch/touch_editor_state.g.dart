// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'touch_editor_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TouchEditorStateNotifier)
const touchEditorStateProvider = TouchEditorStateNotifierProvider._();

final class TouchEditorStateNotifierProvider
    extends $NotifierProvider<TouchEditorStateNotifier, TouchEditorState> {
  const TouchEditorStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'touchEditorStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$touchEditorStateNotifierHash();

  @$internal
  @override
  TouchEditorStateNotifier create() => TouchEditorStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TouchEditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TouchEditorState>(value),
    );
  }
}

String _$touchEditorStateNotifierHash() =>
    r'd15afec0e59b3e5846e5e08fb916d0bfde3a5c9f';

abstract class _$TouchEditorStateNotifier extends $Notifier<TouchEditorState> {
  TouchEditorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TouchEditorState, TouchEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TouchEditorState, TouchEditorState>,
              TouchEditorState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TouchEditorMoveIndex)
const touchEditorMoveIndexProvider = TouchEditorMoveIndexProvider._();

final class TouchEditorMoveIndexProvider
    extends $NotifierProvider<TouchEditorMoveIndex, int?> {
  const TouchEditorMoveIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'touchEditorMoveIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$touchEditorMoveIndexHash();

  @$internal
  @override
  TouchEditorMoveIndex create() => TouchEditorMoveIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$touchEditorMoveIndexHash() =>
    r'bd4bb17bd8548f069a4448a0c8d356e46664c338';

abstract class _$TouchEditorMoveIndex extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
