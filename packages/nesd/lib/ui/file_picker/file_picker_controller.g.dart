// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_picker_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FilePickerStateNotifier)
final filePickerStateProvider = FilePickerStateNotifierProvider._();

final class FilePickerStateNotifierProvider
    extends $NotifierProvider<FilePickerStateNotifier, FilePickerState> {
  FilePickerStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filePickerStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filePickerStateNotifierHash();

  @$internal
  @override
  FilePickerStateNotifier create() => FilePickerStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilePickerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilePickerState>(value),
    );
  }
}

String _$filePickerStateNotifierHash() =>
    r'9d6dc76afb6e5c7f330e476157b557820557a00a';

abstract class _$FilePickerStateNotifier extends $Notifier<FilePickerState> {
  FilePickerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FilePickerState, FilePickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FilePickerState, FilePickerState>,
              FilePickerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filePickerController)
final filePickerControllerProvider = FilePickerControllerProvider._();

final class FilePickerControllerProvider
    extends
        $FunctionalProvider<
          FilePickerController,
          FilePickerController,
          FilePickerController
        >
    with $Provider<FilePickerController> {
  FilePickerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filePickerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filePickerControllerHash();

  @$internal
  @override
  $ProviderElement<FilePickerController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FilePickerController create(Ref ref) {
    return filePickerController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilePickerController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilePickerController>(value),
    );
  }
}

String _$filePickerControllerHash() =>
    r'b3fed563e617cec711931378e3bd7b4c14f9f67d';
