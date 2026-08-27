import 'package:flutter/material.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/theme/base.dart';

const logTimestampColor = Colors.white38;

Color logLevelColor(LogLevel level) => switch (level) {
  LogLevel.debug => Colors.white54,
  LogLevel.info => Colors.white,
  LogLevel.warning => Colors.orange,
  LogLevel.error => nesdRed.shade300,
};

Color logChannelColor(LogChannel channel) => switch (channel) {
  LogChannel.app => Colors.blue.shade300,
  LogChannel.rom => Colors.deepPurple.shade200,
  LogChannel.emulator => Colors.cyan.shade300,
  LogChannel.audio => Colors.green.shade300,
  LogChannel.video => Colors.pink.shade200,
  LogChannel.input => Colors.lime.shade300,
  LogChannel.settings => Colors.teal.shade200,
  LogChannel.storage => Colors.indigo.shade200,
  LogChannel.telemetry => Colors.blueGrey.shade300,
};
