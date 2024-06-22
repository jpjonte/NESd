import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/apu/apu.dart';
import 'package:nes/nes/apu/frame_counter/frame_counter_state.dart';

class FrameCounter {
  FrameCounter(this.apu);

  final APU apu;

  int counter = 0;

  bool fiveStep = false;

  bool interrupt = false;
  bool interruptInhibit = false;

  FrameCounterState get state => FrameCounterState(
        counter: counter,
        fiveStep: fiveStep,
        interrupt: interrupt,
        interruptInhibit: interruptInhibit,
      );

  set state(FrameCounterState value) {
    counter = value.counter;
    fiveStep = value.fiveStep;
    interrupt = value.interrupt;
    interruptInhibit = value.interruptInhibit;
  }

  void reset() {
    counter = 0;

    fiveStep = false;

    interrupt = false;
    interruptInhibit = false;
  }

  int get status {
    final value = interrupt ? 1 : 0;

    // TODO
    // If an interrupt flag was set at the same moment of the read,
    // it will read back as 1 but it will not be cleared.
    interrupt = false;

    return value;
  }

  void writeControl(int value) {
    fiveStep = value.bit(7) == 1;

    interruptInhibit = value.bit(6) == 1;

    if (interruptInhibit) {
      interrupt = false;
    }

    // TODO Side effects
    // After 3 or 4 CPU clock cycles*, the timer is reset.
    // If the mode flag is set, then both "quarter frame" and "half frame"
    // signals are also generated.

    counter = 0;

    // TODO
    if (fiveStep) {
      _doFrameCounter5Step(1);
      _doFrameCounter5Step(2);
    }

    // * If the write occurs during an APU cycle, the effects occur 3 CPU
    // cycles after the $4017 write cycle, and if the write occurs between
    // APU cycles, the effects occurs 4 CPU cycles after the write cycle.
  }

  void step() {
    if (fiveStep) {
      _stepFrameCounter5StepMode();
    } else {
      _stepFrameCounter4StepMode();
    }

    counter++;
  }

  void _stepFrameCounter4StepMode() {
    switch (counter) {
      case 3728: // 3728.5
        _doFrameCounter4Step(0);
      case 7456: // 7456.5
        _doFrameCounter4Step(1);
      case 11185: // 11185.5
        _doFrameCounter4Step(2);
      case 14914: // 14914.5
        _doFrameCounter4Step(3);
        counter = 0;
    }
  }

  void _doFrameCounter4Step(int step) {
    switch (step) {
      case 0:
      case 2:
        _stepEnvelopes();
        apu.triangle.stepLinearCounter();
      case 1:
        _stepEnvelopes();
        _stepLengthCounters();
        _stepSweeps();
        apu.triangle.stepLinearCounter();
      case 3:
        _stepEnvelopes();
        _stepLengthCounters();
        _stepSweeps();
        apu.triangle.stepLinearCounter();

        if (!interruptInhibit) {
          interrupt = true;

          apu.bus.triggerIrq();
        }
    }
  }

  void _stepFrameCounter5StepMode() {
    switch (counter) {
      case 3728: // 3728.5
        _doFrameCounter5Step(0);
      case 7456: // 7456.5
        _doFrameCounter5Step(1);
      case 11185: // 11185.5
        _doFrameCounter5Step(2);
      case 14914: // 14914.5
        _doFrameCounter5Step(3);
      case 18640: // 18640.5
        _doFrameCounter5Step(4);
        counter = 0;
    }
  }

  void _doFrameCounter5Step(int step) {
    switch (step) {
      case 0:
      case 2:
        _stepEnvelopes();
        apu.triangle.stepLinearCounter();
      case 1:
      case 4:
        _stepEnvelopes();
        _stepLengthCounters();
        _stepSweeps();
        apu.triangle.stepLinearCounter();
      case 3:
        break; // do nothing
    }
  }

  void _stepEnvelopes() {
    apu.pulse1.envelope.step();
    apu.pulse2.envelope.step();
    apu.noise.envelope.step();
  }

  void _stepLengthCounters() {
    apu.pulse1.lengthCounter.step();
    apu.pulse2.lengthCounter.step();
    apu.triangle.lengthCounter.step();
    apu.noise.lengthCounter.step();
  }

  void _stepSweeps() {
    apu.pulse1.sweep.step();
    apu.pulse2.sweep.step();
  }
}
