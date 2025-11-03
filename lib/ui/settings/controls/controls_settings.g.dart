// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controls_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(maxIndex)
const maxIndexProvider = MaxIndexProvider._();

final class MaxIndexProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  const MaxIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maxIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maxIndexHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return maxIndex(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$maxIndexHash() => r'eb1f948d0c86a333e6e6949cbcfc609dd607c24c';

@ProviderFor(ProfileIndex)
const profileIndexProvider = ProfileIndexProvider._();

final class ProfileIndexProvider extends $NotifierProvider<ProfileIndex, int> {
  const ProfileIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileIndexHash();

  @$internal
  @override
  ProfileIndex create() => ProfileIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$profileIndexHash() => r'c78cc409988640f0b8ec85a5e9df36df50f5eeec';

abstract class _$ProfileIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
