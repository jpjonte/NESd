import 'dart:math';

import 'package:nes/nes/apu/channel/pulse_channel.dart';

class SweepUnit {
  SweepUnit(this.channel, {this.onesComplement = false});

  final PulseChannel channel;
  final bool onesComplement;

  bool enabled = false;
  bool muting = false;

  int value = 0;
  int period = 0;
  int shift = 0;

  bool negate = false;
  bool reload = false;

  void reset() {
    enabled = false;
    value = 0;
    period = 0;
    shift = 0;
    negate = false;
    reload = false;
  }

  void step() {
    final targetPeriod = calculateTargetPeriod();

    muting = channel.timerPeriod < 8 || targetPeriod > 0x7FF;

    if (value == 0 && enabled && shift > 0 && !muting) {
      channel.timerPeriod = targetPeriod;
    }

    if (value == 0 || reload) {
      value = period;
      reload = false;
    } else {
      value--;
    }
  }

  int calculateTargetPeriod() {
    final delta = channel.timerPeriod >> shift;
    final result = channel.timerPeriod +
        (negate ? -delta - (onesComplement ? 1 : 0) : delta);

    return max(0, result);
  }
}
