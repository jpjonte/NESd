// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_states_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(saveStatesScreenController)
final saveStatesScreenControllerProvider = SaveStatesScreenControllerFamily._();

final class SaveStatesScreenControllerProvider
    extends
        $FunctionalProvider<
          SaveStatesScreenController,
          SaveStatesScreenController,
          SaveStatesScreenController
        >
    with $Provider<SaveStatesScreenController> {
  SaveStatesScreenControllerProvider._({
    required SaveStatesScreenControllerFamily super.from,
    required RomInfo super.argument,
  }) : super(
         retry: null,
         name: r'saveStatesScreenControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saveStatesScreenControllerHash();

  @override
  String toString() {
    return r'saveStatesScreenControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SaveStatesScreenController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveStatesScreenController create(Ref ref) {
    final argument = this.argument as RomInfo;
    return saveStatesScreenController(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveStatesScreenController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveStatesScreenController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SaveStatesScreenControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveStatesScreenControllerHash() =>
    r'792be9e91109fd344d9f48755510b75f1d459488';

final class SaveStatesScreenControllerFamily extends $Family
    with $FunctionalFamilyOverride<SaveStatesScreenController, RomInfo> {
  SaveStatesScreenControllerFamily._()
    : super(
        retry: null,
        name: r'saveStatesScreenControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaveStatesScreenControllerProvider call(RomInfo romInfo) =>
      SaveStatesScreenControllerProvider._(argument: romInfo, from: this);

  @override
  String toString() => r'saveStatesScreenControllerProvider';
}
