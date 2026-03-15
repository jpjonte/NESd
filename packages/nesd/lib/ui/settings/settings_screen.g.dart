// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsTabIndex)
final settingsTabIndexProvider = SettingsTabIndexProvider._();

final class SettingsTabIndexProvider
    extends $NotifierProvider<SettingsTabIndex, int> {
  SettingsTabIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsTabIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsTabIndexHash();

  @$internal
  @override
  SettingsTabIndex create() => SettingsTabIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$settingsTabIndexHash() => r'c5953f1669eb7fbfa7490a16747950296c9c2b53';

abstract class _$SettingsTabIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
