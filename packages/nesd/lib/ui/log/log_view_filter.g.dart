// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_view_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LogViewFilter)
final logViewFilterProvider = LogViewFilterProvider._();

final class LogViewFilterProvider
    extends $NotifierProvider<LogViewFilter, LogViewFilterState> {
  LogViewFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logViewFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logViewFilterHash();

  @$internal
  @override
  LogViewFilter create() => LogViewFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogViewFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogViewFilterState>(value),
    );
  }
}

String _$logViewFilterHash() => r'0cffad86cea8113e591f2d4d6678af9577adb67c';

abstract class _$LogViewFilter extends $Notifier<LogViewFilterState> {
  LogViewFilterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LogViewFilterState, LogViewFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LogViewFilterState, LogViewFilterState>,
              LogViewFilterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
