// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disassembler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(disassembler)
const disassemblerProvider = DisassemblerProvider._();

final class DisassemblerProvider
    extends
        $FunctionalProvider<
          DisassemblerInterface,
          DisassemblerInterface,
          DisassemblerInterface
        >
    with $Provider<DisassemblerInterface> {
  const DisassemblerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disassemblerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disassemblerHash();

  @$internal
  @override
  $ProviderElement<DisassemblerInterface> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DisassemblerInterface create(Ref ref) {
    return disassembler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisassemblerInterface value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisassemblerInterface>(value),
    );
  }
}

String _$disassemblerHash() => r'aecf898fa0e7b33d8fd0c435ec5f85ba28df0d15';
