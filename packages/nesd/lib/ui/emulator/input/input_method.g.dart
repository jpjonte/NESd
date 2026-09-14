// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_method.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the input method used most recently anywhere in the app: any key
/// press, mouse click or scroll, gamepad press, or touch switches it.

@ProviderFor(RecentInputMethod)
final recentInputMethodProvider = RecentInputMethodProvider._();

/// Tracks the input method used most recently anywhere in the app: any key
/// press, mouse click or scroll, gamepad press, or touch switches it.
final class RecentInputMethodProvider
    extends $NotifierProvider<RecentInputMethod, RecentInput> {
  /// Tracks the input method used most recently anywhere in the app: any key
  /// press, mouse click or scroll, gamepad press, or touch switches it.
  RecentInputMethodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentInputMethodProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentInputMethodHash();

  @$internal
  @override
  RecentInputMethod create() => RecentInputMethod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentInput value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentInput>(value),
    );
  }
}

String _$recentInputMethodHash() => r'4cf0a39ee8619501a754f49f42b899f134310d99';

/// Tracks the input method used most recently anywhere in the app: any key
/// press, mouse click or scroll, gamepad press, or touch switches it.

abstract class _$RecentInputMethod extends $Notifier<RecentInput> {
  RecentInput build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecentInput, RecentInput>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecentInput, RecentInput>,
              RecentInput,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
