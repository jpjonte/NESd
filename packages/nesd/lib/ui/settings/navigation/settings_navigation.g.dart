// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_navigation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsNavigation)
final settingsNavigationProvider = SettingsNavigationProvider._();

final class SettingsNavigationProvider
    extends $NotifierProvider<SettingsNavigation, SettingsNavigationState> {
  SettingsNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsNavigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNavigationHash();

  @$internal
  @override
  SettingsNavigation create() => SettingsNavigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsNavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsNavigationState>(value),
    );
  }
}

String _$settingsNavigationHash() =>
    r'6e96c084c59bf22f322ff640c4edd0b109bcb14a';

abstract class _$SettingsNavigation extends $Notifier<SettingsNavigationState> {
  SettingsNavigationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SettingsNavigationState, SettingsNavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettingsNavigationState, SettingsNavigationState>,
              SettingsNavigationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
