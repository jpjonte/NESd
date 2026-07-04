import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/triangle_channel_state.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit.dart';

class TriangleChannel {
  bool enabled = false;

  final lengthCounter = LengthCounterUnit();

  bool control = false;

  int dutyIndex = 0;

  int linearCounterPeriod = 0;
  int linearCounter = 0;

  int timer = 0;
  int timerPeriod = 0;

  bool reload = false;

  int output = 0;

  TriangleChannelState get state => TriangleChannelState(
    enabled: enabled,
    control: control,
    dutyIndex: dutyIndex,
    linearCounterPeriod: linearCounterPeriod,
    linearCounter: linearCounter,
    timer: timer,
    timerPeriod: timerPeriod,
    reload: reload,
    lengthCounterState: lengthCounter.state,
  );

  set state(TriangleChannelState state) {
    enabled = state.enabled;
    control = state.control;
    dutyIndex = state.dutyIndex;
    linearCounterPeriod = state.linearCounterPeriod;
    linearCounter = state.linearCounter;
    timer = state.timer;
    timerPeriod = state.timerPeriod;
    reload = state.reload;
    lengthCounter.state = state.lengthCounterState;

    _updateOutput();
  }

  void reset() {
    enabled = false;
    linearCounter = 0;
    timer = 0;

    lengthCounter.reset();

    _updateOutput();
  }

  int get status => lengthCounter.value > 0 ? 1 : 0;

  set status(int value) {
    enabled = value.bit(2) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }

    _updateOutput();
  }

  void writeControl(int value) {
    lengthCounter.halt = value.bit(7) == 1;
    control = value.bit(7) == 1;
    linearCounterPeriod = value & 0x7f;

    _updateOutput();
  }

  void writeTimerLow(int value) {
    timerPeriod = (timerPeriod & 0x700) | value;

    _updateOutput();
  }

  void writeTimerHigh(int value) {
    timerPeriod = (timerPeriod & 0x00FF) | ((value & 7) << 8);
    reload = true;

    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }

    _updateOutput();
  }

  void stepLinearCounter() {
    if (reload) {
      linearCounter = linearCounterPeriod;
    } else if (linearCounter > 0) {
      linearCounter--;
    }

    if (!control) {
      reload = false;
    }

    _updateOutput();
  }

  void clockLengthCounter() {
    lengthCounter.step();

    _updateOutput();
  }

  @pragma('vm:prefer-inline')
  void step() {
    if (timerPeriod < 2 && timer == 0) {
      return;
    }

    if (lengthCounter.value == 0) {
      return;
    }

    if (linearCounter == 0) {
      return;
    }

    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;
      dutyIndex = (dutyIndex + 1) & 31;

      _updateOutput();
    }
  }

  @pragma('vm:prefer-inline')
  void _updateOutput() {
    if (!enabled) {
      output = 0;

      return;
    }

    if (timerPeriod < 2) {
      output = 7; // 7.5

      return;
    }

    if (lengthCounter.value == 0) {
      output = 0;

      return;
    }

    if (linearCounter == 0) {
      output = 0;

      return;
    }

    output = triangleTable[dutyIndex];
  }
}
