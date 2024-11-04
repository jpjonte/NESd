// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$binderControllerHash() => r'f42f092667fcf60543f7a0ce71db66381d188ff1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [binderController].
@ProviderFor(binderController)
const binderControllerProvider = BinderControllerFamily();

/// See also [binderController].
class BinderControllerFamily extends Family<BinderController> {
  /// See also [binderController].
  const BinderControllerFamily();

  /// See also [binderController].
  BinderControllerProvider call(
    NesAction action,
  ) {
    return BinderControllerProvider(
      action,
    );
  }

  @override
  BinderControllerProvider getProviderOverride(
    covariant BinderControllerProvider provider,
  ) {
    return call(
      provider.action,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'binderControllerProvider';
}

/// See also [binderController].
class BinderControllerProvider extends AutoDisposeProvider<BinderController> {
  /// See also [binderController].
  BinderControllerProvider(
    NesAction action,
  ) : this._internal(
          (ref) => binderController(
            ref as BinderControllerRef,
            action,
          ),
          from: binderControllerProvider,
          name: r'binderControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$binderControllerHash,
          dependencies: BinderControllerFamily._dependencies,
          allTransitiveDependencies:
              BinderControllerFamily._allTransitiveDependencies,
          action: action,
        );

  BinderControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.action,
  }) : super.internal();

  final NesAction action;

  @override
  Override overrideWith(
    BinderController Function(BinderControllerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BinderControllerProvider._internal(
        (ref) => create(ref as BinderControllerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        action: action,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<BinderController> createElement() {
    return _BinderControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinderControllerProvider && other.action == action;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, action.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BinderControllerRef on AutoDisposeProviderRef<BinderController> {
  /// The parameter `action` of this provider.
  NesAction get action;
}

class _BinderControllerProviderElement
    extends AutoDisposeProviderElement<BinderController>
    with BinderControllerRef {
  _BinderControllerProviderElement(super.provider);

  @override
  NesAction get action => (origin as BinderControllerProvider).action;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
