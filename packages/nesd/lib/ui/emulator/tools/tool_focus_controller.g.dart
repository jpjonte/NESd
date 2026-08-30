// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_focus_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the tool panel owns input instead of the game.
///
/// Transient: deliberately not part of the persisted `settings.openTools`.

@ProviderFor(ToolFocusController)
final toolFocusControllerProvider = ToolFocusControllerProvider._();

/// Whether the tool panel owns input instead of the game.
///
/// Transient: deliberately not part of the persisted `settings.openTools`.
final class ToolFocusControllerProvider
    extends $NotifierProvider<ToolFocusController, bool> {
  /// Whether the tool panel owns input instead of the game.
  ///
  /// Transient: deliberately not part of the persisted `settings.openTools`.
  ToolFocusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolFocusControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolFocusControllerHash();

  @$internal
  @override
  ToolFocusController create() => ToolFocusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$toolFocusControllerHash() =>
    r'98010d48f53346a5d1b55cdf3685145fea41200e';

/// Whether the tool panel owns input instead of the game.
///
/// Transient: deliberately not part of the persisted `settings.openTools`.

abstract class _$ToolFocusController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
