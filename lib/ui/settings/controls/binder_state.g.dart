// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'binder_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$binderStateHash() => r'88eeaee2f651483d321eae975f64c813262fd17f';

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

abstract class _$BinderState extends BuildlessAutoDisposeNotifier<
    ({bool editing, InputCombination? input})> {
  late final NesAction action;

  ({bool editing, InputCombination? input}) build(
    NesAction action,
  );
}

/// See also [BinderState].
@ProviderFor(BinderState)
const binderStateProvider = BinderStateFamily();

/// See also [BinderState].
class BinderStateFamily
    extends Family<({bool editing, InputCombination? input})> {
  /// See also [BinderState].
  const BinderStateFamily();

  /// See also [BinderState].
  BinderStateProvider call(
    NesAction action,
  ) {
    return BinderStateProvider(
      action,
    );
  }

  @override
  BinderStateProvider getProviderOverride(
    covariant BinderStateProvider provider,
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
  String? get name => r'binderStateProvider';
}

/// See also [BinderState].
class BinderStateProvider extends AutoDisposeNotifierProviderImpl<BinderState,
    ({bool editing, InputCombination? input})> {
  /// See also [BinderState].
  BinderStateProvider(
    NesAction action,
  ) : this._internal(
          () => BinderState()..action = action,
          from: binderStateProvider,
          name: r'binderStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$binderStateHash,
          dependencies: BinderStateFamily._dependencies,
          allTransitiveDependencies:
              BinderStateFamily._allTransitiveDependencies,
          action: action,
        );

  BinderStateProvider._internal(
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
  ({bool editing, InputCombination? input}) runNotifierBuild(
    covariant BinderState notifier,
  ) {
    return notifier.build(
      action,
    );
  }

  @override
  Override overrideWith(BinderState Function() create) {
    return ProviderOverride(
      origin: this,
      override: BinderStateProvider._internal(
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
  AutoDisposeNotifierProviderElement<BinderState,
      ({bool editing, InputCombination? input})> createElement() {
    return _BinderStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinderStateProvider && other.action == action;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, action.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BinderStateRef on AutoDisposeNotifierProviderRef<
    ({bool editing, InputCombination? input})> {
  /// The parameter `action` of this provider.
  NesAction get action;
}

class _BinderStateProviderElement extends AutoDisposeNotifierProviderElement<
    BinderState,
    ({bool editing, InputCombination? input})> with BinderStateRef {
  _BinderStateProviderElement(super.provider);

  @override
  NesAction get action => (origin as BinderStateProvider).action;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
