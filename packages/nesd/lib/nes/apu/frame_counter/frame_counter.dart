import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/region.dart';

// sequencer step points in CPU cycles
const ntscQuarter1 = 7457;
const ntscQuarter2 = 14913;
const ntscQuarter3 = 22371;
const ntscFourStepEnd = 29830;
const ntscFiveStepEnd = 37282;

const palQuarter1 = 8313;
const palQuarter2 = 16627;
const palQuarter3 = 24939;
const palFourStepEnd = 33254;
const palFiveStepEnd = 41566;

const resetDividerOffset = 7;

class FrameCounter {
  FrameCounter(this.apu);

  final APU apu;

  int counter = 0;

  int resetDelay = 0;

  bool fiveStep = false;

  bool interrupt = false;
  bool interruptInhibit = false;

  int _quarter1 = ntscQuarter1;
  int _quarter2 = ntscQuarter2;
  int _quarter3 = ntscQuarter3;
  int _fourStepEnd = ntscFourStepEnd;
  int _fiveStepEnd = ntscFiveStepEnd;

  FrameCounterState get state => FrameCounterState(
    counter: counter,
    resetDelay: resetDelay,
    fiveStep: fiveStep,
    interrupt: interrupt,
    interruptInhibit: interruptInhibit,
  );

  set state(FrameCounterState value) {
    counter = value.counter;
    resetDelay = value.resetDelay;
    fiveStep = value.fiveStep;
    interrupt = value.interrupt;
    interruptInhibit = value.interruptInhibit;
  }

  // we don't need a getter
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    switch (region) {
      case Region.ntsc:
        _quarter1 = ntscQuarter1;
        _quarter2 = ntscQuarter2;
        _quarter3 = ntscQuarter3;
        _fourStepEnd = ntscFourStepEnd;
        _fiveStepEnd = ntscFiveStepEnd;
      case Region.pal:
        _quarter1 = palQuarter1;
        _quarter2 = palQuarter2;
        _quarter3 = palQuarter3;
        _fourStepEnd = palFourStepEnd;
        _fiveStepEnd = palFiveStepEnd;
    }
  }

  void reset() {
    counter = resetDividerOffset;
    resetDelay = 0;

    fiveStep = false;

    interrupt = false;
    interruptInhibit = false;
  }

  void softReset() {
    counter = resetDividerOffset;
    resetDelay = 0;

    interrupt = false;

    apu.bus.clearIrq(IrqSource.apuFrameCounter);

    if (fiveStep) {
      _clockQuarterFrame();
      _clockHalfFrame();
    }
  }

  int getStatus({bool disableSideEffects = false}) {
    final value = interrupt ? 1 : 0;

    if (!disableSideEffects) {
      interrupt = false;

      apu.bus.clearIrq(IrqSource.apuFrameCounter);
    }

    return value;
  }

  void writeControl(int value) {
    fiveStep = value.bit(7) == 1;

    interruptInhibit = value.bit(6) == 1;

    if (interruptInhibit) {
      interrupt = false;

      apu.bus.clearIrq(IrqSource.apuFrameCounter);
    }

    // The divider resets 3 CPU cycles after a write on an APU cycle and 4
    // after a write between APU cycles, so the reset always lands on the
    // same APU phase.
    resetDelay = apu.cycles.isOdd ? 3 : 4;
  }

  @pragma('vm:prefer-inline')
  void step() {
    if (resetDelay > 0) {
      resetDelay--;

      if (resetDelay == 0) {
        _resetDivider();

        return;
      }
    }

    counter++;

    if (counter == _quarter1 || counter == _quarter3) {
      _clockQuarterFrame();
    } else if (counter == _quarter2) {
      _clockQuarterFrame();
      _clockHalfFrame();
    } else if (fiveStep) {
      _stepFiveStepEnd();
    } else {
      _stepFourStepEnd();
    }
  }

  void _resetDivider() {
    counter = 0;

    if (fiveStep) {
      _clockQuarterFrame();
      _clockHalfFrame();
    }
  }

  // The frame interrupt flag is raised on the last three cycles of the
  // 4-step sequence, which reads of $4015 observe as three consecutive sets.
  void _stepFourStepEnd() {
    if (counter == _fourStepEnd - 2) {
      _raiseInterrupt();
    } else if (counter == _fourStepEnd - 1) {
      _raiseInterrupt();
      _clockQuarterFrame();
      _clockHalfFrame();
    } else if (counter == _fourStepEnd) {
      _raiseInterrupt();
      counter = 0;
    }
  }

  void _stepFiveStepEnd() {
    if (counter == _fiveStepEnd - 1) {
      _clockQuarterFrame();
      _clockHalfFrame();
    } else if (counter == _fiveStepEnd) {
      counter = 0;
    }
  }

  void _raiseInterrupt() {
    if (interruptInhibit) {
      return;
    }

    interrupt = true;

    apu.bus.triggerIrq(IrqSource.apuFrameCounter);
  }

  void _clockQuarterFrame() {
    apu.pulse1.clockEnvelope();
    apu.pulse2.clockEnvelope();
    apu.noise.clockEnvelope();
    apu.triangle.stepLinearCounter();
  }

  void _clockHalfFrame() {
    apu.pulse1.clockLengthCounter();
    apu.pulse2.clockLengthCounter();
    apu.triangle.clockLengthCounter();
    apu.noise.clockLengthCounter();

    apu.pulse1.clockSweep();
    apu.pulse2.clockSweep();
  }
}
