enum LogChannel {
  app('App'),
  rom('ROM'),
  emulator('Emulator'),
  audio('Audio'),
  video('Video'),
  input('Input'),
  settings('Settings'),
  storage('Storage'),
  telemetry('Telemetry');

  const LogChannel(this.title);

  final String title;
}
