import 'package:nesd/nes/apu/unit/envelope_unit_state.dart';

class EnvelopeUnit {
  int volume = 0;
  int period = 0;
  int timer = 0;
  bool start = false;
  bool loop = false;

  EnvelopeUnitState get state => EnvelopeUnitState(
    volume: volume,
    period: period,
    timer: timer,
    start: start,
    loop: loop,
  );

  set state(EnvelopeUnitState value) {
    volume = value.volume;
    period = value.period;
    timer = value.timer;
    start = value.start;
    loop = value.loop;
  }

  void reset() {
    volume = 0;
    period = 0;
    timer = 0;
    start = false;
    loop = false;
  }

  void step() {
    if (start) {
      volume = 15;
      timer = period;
      start = false;
    } else if (timer > 0) {
      timer--;
    } else {
      timer = period;

      if (volume > 0) {
        volume--;
      } else if (loop) {
        volume = 15;
      }
    }
  }
}
