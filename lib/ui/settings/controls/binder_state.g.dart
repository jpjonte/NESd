// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binder_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$binderStateNotifierHash() =>
    r'027109c0744a948f497bfff2f31f419e88849203';

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

abstract class _$BinderStateNotifier
    extends BuildlessAutoDisposeNotifier<BinderState> {
  late final InputAction action;

  BinderState build(InputAction action);
}

/// See also [BinderStateNotifier].
@ProviderFor(BinderStateNotifier)
const binderStateNotifierProvider = BinderStateNotifierFamily();

/// See also [BinderStateNotifier].
class BinderStateNotifierFamily extends Family<BinderState> {
  /// See also [BinderStateNotifier].
  const BinderStateNotifierFamily();

  /// See also [BinderStateNotifier].
  BinderStateNotifierProvider call(InputAction action) {
    return BinderStateNotifierProvider(action);
  }

  @override
  BinderStateNotifierProvider getProviderOverride(
    covariant BinderStateNotifierProvider provider,
  ) {
    return call(provider.action);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'binderStateNotifierProvider';
}

/// See also [BinderStateNotifier].
class BinderStateNotifierProvider
    extends AutoDisposeNotifierProviderImpl<BinderStateNotifier, BinderState> {
  /// See also [BinderStateNotifier].
  BinderStateNotifierProvider(InputAction action)
    : this._internal(
        () => BinderStateNotifier()..action = action,
        from: binderStateNotifierProvider,
        name: r'binderStateNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$binderStateNotifierHash,
        dependencies: BinderStateNotifierFamily._dependencies,
        allTransitiveDependencies:
            BinderStateNotifierFamily._allTransitiveDependencies,
        action: action,
      );

  BinderStateNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.action,
  }) : super.internal();

  final InputAction action;

  @override
  BinderState runNotifierBuild(covariant BinderStateNotifier notifier) {
    return notifier.build(action);
  }

  @override
  Override overrideWith(BinderStateNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BinderStateNotifierProvider._internal(
        () => create()..action = action,
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
  AutoDisposeNotifierProviderElement<BinderStateNotifier, BinderState>
  createElement() {
    return _BinderStateNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinderStateNotifierProvider && other.action == action;
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
mixin BinderStateNotifierRef on AutoDisposeNotifierProviderRef<BinderState> {
  /// The parameter `action` of this provider.
  InputAction get action;
}

class _BinderStateNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<BinderStateNotifier, BinderState>
    with BinderStateNotifierRef {
  _BinderStateNotifierProviderElement(super.provider);

  @override
  InputAction get action => (origin as BinderStateNotifierProvider).action;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
