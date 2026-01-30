// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<NesDatabase, NesDatabase, NesDatabase>
    with $Provider<NesDatabase> {
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<NesDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NesDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NesDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NesDatabase>(value),
    );
  }
}

String _$databaseHash() => r'd4c12c219f61d2800ca946218a24777f84d5d116';
