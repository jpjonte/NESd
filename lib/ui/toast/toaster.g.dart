// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toaster.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$toasterHash() => r'2830927222b4b7cbe3e48cf7ec0133c86ac4efc9';

/// See also [toaster].
@ProviderFor(toaster)
final toasterProvider = AutoDisposeProvider<Toaster>.internal(
  toaster,
  name: r'toasterProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$toasterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ToasterRef = AutoDisposeProviderRef<Toaster>;
String _$toastStateHash() => r'88d1781167cc6aeef3d9c286fba818397aed6103';

/// See also [ToastState].
@ProviderFor(ToastState)
final toastStateProvider =
    AutoDisposeNotifierProvider<ToastState, List<Toast>>.internal(
      ToastState.new,
      name: r'toastStateProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$toastStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ToastState = AutoDisposeNotifier<List<Toast>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
