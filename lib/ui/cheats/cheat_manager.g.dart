// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheat_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheatManager)
final cheatManagerProvider = CheatManagerFamily._();

final class CheatManagerProvider
    extends $NotifierProvider<CheatManager, List<Cheat>> {
  CheatManagerProvider._({
    required CheatManagerFamily super.from,
    required RomInfo super.argument,
  }) : super(
         retry: null,
         name: r'cheatManagerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cheatManagerHash();

  @override
  String toString() {
    return r'cheatManagerProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is CheatManagerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cheatManagerHash() => r'3b421f9310f062ac3e9ca5c72eef2d3962c58342';

final class CheatManagerFamily extends $Family
    with
        $ClassFamilyOverride<
          CheatManager,
          List<Cheat>,
          List<Cheat>,
          List<Cheat>,
          RomInfo
        > {
  CheatManagerFamily._()
    : super(
        retry: null,
        name: r'cheatManagerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CheatManagerProvider call(RomInfo romInfo) =>
      CheatManagerProvider._(argument: romInfo, from: this);

  @override
  String toString() => r'cheatManagerProvider';
}

abstract class _$CheatManager extends $Notifier<List<Cheat>> {
  late final _$args = ref.$arg as RomInfo;
  RomInfo get romInfo => _$args;

  List<Cheat> build(RomInfo romInfo);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Cheat>, List<Cheat>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Cheat>, List<Cheat>>,
              List<Cheat>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
