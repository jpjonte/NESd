// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_states_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$saveStatesScreenControllerHash() =>
    r'1af0d109862f428a3b1049e8a8e6121c4734e1b3';

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

/// See also [saveStatesScreenController].
@ProviderFor(saveStatesScreenController)
const saveStatesScreenControllerProvider = SaveStatesScreenControllerFamily();

/// See also [saveStatesScreenController].
class SaveStatesScreenControllerFamily
    extends Family<SaveStatesScreenController> {
  /// See also [saveStatesScreenController].
  const SaveStatesScreenControllerFamily();

  /// See also [saveStatesScreenController].
  SaveStatesScreenControllerProvider call(RomInfo romInfo) {
    return SaveStatesScreenControllerProvider(romInfo);
  }

  @override
  SaveStatesScreenControllerProvider getProviderOverride(
    covariant SaveStatesScreenControllerProvider provider,
  ) {
    return call(provider.romInfo);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'saveStatesScreenControllerProvider';
}

/// See also [saveStatesScreenController].
class SaveStatesScreenControllerProvider
    extends AutoDisposeProvider<SaveStatesScreenController> {
  /// See also [saveStatesScreenController].
  SaveStatesScreenControllerProvider(RomInfo romInfo)
    : this._internal(
        (ref) => saveStatesScreenController(
          ref as SaveStatesScreenControllerRef,
          romInfo,
        ),
        from: saveStatesScreenControllerProvider,
        name: r'saveStatesScreenControllerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$saveStatesScreenControllerHash,
        dependencies: SaveStatesScreenControllerFamily._dependencies,
        allTransitiveDependencies:
            SaveStatesScreenControllerFamily._allTransitiveDependencies,
        romInfo: romInfo,
      );

  SaveStatesScreenControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.romInfo,
  }) : super.internal();

  final RomInfo romInfo;

  @override
  Override overrideWith(
    SaveStatesScreenController Function(SaveStatesScreenControllerRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SaveStatesScreenControllerProvider._internal(
        (ref) => create(ref as SaveStatesScreenControllerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        romInfo: romInfo,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<SaveStatesScreenController> createElement() {
    return _SaveStatesScreenControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveStatesScreenControllerProvider &&
        other.romInfo == romInfo;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, romInfo.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SaveStatesScreenControllerRef
    on AutoDisposeProviderRef<SaveStatesScreenController> {
  /// The parameter `romInfo` of this provider.
  RomInfo get romInfo;
}

class _SaveStatesScreenControllerProviderElement
    extends AutoDisposeProviderElement<SaveStatesScreenController>
    with SaveStatesScreenControllerRef {
  _SaveStatesScreenControllerProviderElement(super.provider);

  @override
  RomInfo get romInfo => (origin as SaveStatesScreenControllerProvider).romInfo;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
