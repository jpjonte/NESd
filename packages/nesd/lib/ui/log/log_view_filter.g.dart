// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_view_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewer's filter selections, kept alive so they survive leaving and
/// reopening the screen. Deliberately not persisted to disk — a fresh app
/// launch starts unfiltered.

@ProviderFor(LogViewFilter)
final logViewFilterProvider = LogViewFilterProvider._();

/// The viewer's filter selections, kept alive so they survive leaving and
/// reopening the screen. Deliberately not persisted to disk — a fresh app
/// launch starts unfiltered.
final class LogViewFilterProvider
    extends $NotifierProvider<LogViewFilter, LogViewFilterState> {
  /// The viewer's filter selections, kept alive so they survive leaving and
  /// reopening the screen. Deliberately not persisted to disk — a fresh app
  /// launch starts unfiltered.
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

String _$logViewFilterHash() => r'104d2b43dfad812b95235f49062eb6ba8d1052df';

/// The viewer's filter selections, kept alive so they survive leaving and
/// reopening the screen. Deliberately not persisted to disk — a fresh app
/// launch starts unfiltered.

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
