// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debugger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(debugger)
final debuggerProvider = DebuggerProvider._();

final class DebuggerProvider
    extends
        $FunctionalProvider<
          DebuggerInterface,
          DebuggerInterface,
          DebuggerInterface
        >
    with $Provider<DebuggerInterface> {
  DebuggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debuggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debuggerHash();

  @$internal
  @override
  $ProviderElement<DebuggerInterface> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DebuggerInterface create(Ref ref) {
    return debugger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DebuggerInterface value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DebuggerInterface>(value),
    );
  }
}

String _$debuggerHash() => r'c9662bee0f1ee9b53e03c11d8a5fa64d82c927b3';
