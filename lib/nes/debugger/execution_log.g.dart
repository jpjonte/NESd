// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_log.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(executionLog)
final executionLogProvider = ExecutionLogProvider._();

final class ExecutionLogProvider
    extends $FunctionalProvider<ExecutionLog, ExecutionLog, ExecutionLog>
    with $Provider<ExecutionLog> {
  ExecutionLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'executionLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$executionLogHash();

  @$internal
  @override
  $ProviderElement<ExecutionLog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExecutionLog create(Ref ref) {
    return executionLog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExecutionLog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExecutionLog>(value),
    );
  }
}

String _$executionLogHash() => r'cf9cda751ff3dbf019d2786520cabe71e837c881';
