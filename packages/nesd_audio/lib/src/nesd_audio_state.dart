/// Kind of device backing a `NesdAudio` stream.
enum NesdAudioState {
  /// Playing on a real output device.
  realDevice,

  /// The null device was requested via `NesdAudio.open(nullDevice:)`.
  nullDevice,

  /// No real device is available right now.
  nullFallback,
}
