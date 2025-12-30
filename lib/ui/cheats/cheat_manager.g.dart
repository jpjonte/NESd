// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheat_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheatManager)
const cheatManagerProvider = CheatManagerProvider._();

final class CheatManagerProvider
    extends $NotifierProvider<CheatManager, List<Cheat>> {
  const CheatManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cheatManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cheatManagerHash();

  @$internal
  @override
  CheatManager create() => CheatManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Cheat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Cheat>>(value),
    );
  }
}

String _$cheatManagerHash() => r'2b69eed07fafe1a51a83fee6491184cde0d44f0d';

abstract class _$CheatManager extends $Notifier<List<Cheat>> {
  List<Cheat> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Cheat>, List<Cheat>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Cheat>, List<Cheat>>,
              List<Cheat>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
