// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_output.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(audioOutput)
const audioOutputProvider = AudioOutputProvider._();

final class AudioOutputProvider
    extends $FunctionalProvider<AudioOutput, AudioOutput, AudioOutput>
    with $Provider<AudioOutput> {
  const AudioOutputProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioOutputProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioOutputHash();

  @$internal
  @override
  $ProviderElement<AudioOutput> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioOutput create(Ref ref) {
    return audioOutput(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioOutput value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioOutput>(value),
    );
  }
}

String _$audioOutputHash() => r'455e7446f72318cb18577ea178a8518f97187bbc';
