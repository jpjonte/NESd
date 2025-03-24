import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/region.dart';

const ntsc4Step0 = 3728; // 3728.5
const ntsc4Step1 = 7456; // 7456.5
const ntsc4Step2 = 11185; // 11185.5
const ntsc4Step3 = 14914; // 14914.5

const pal4Step0 = 4156; // 4156.5
const pal4Step1 = 8313; // 8313.5
const pal4Step2 = 12469; // 12469.5
const pal4Step3 = 16626; // 16626.5

const ntsc5Step0 = 3728; // 3728.5
const ntsc5Step1 = 7456; // 7456.5
const ntsc5Step2 = 11185; // 11185.5
const ntsc5Step3 = 14914; // 14914.5
const ntsc5Step4 = 18640; // 18640.5

const pal5Step0 = 4156; // 4156.5
const pal5Step1 = 8313; // 8313.5
const pal5Step2 = 12469; // 12469.5
const pal5Step3 = 16626; // 16626.5
const pal5Step4 = 20782; // 20782.5

class FrameCounter {
  FrameCounter(this.apu);

  final APU apu;

  int counter = 0;

  bool fiveStep = false;

  bool interrupt = false;
  bool interruptInhibit = false;

  int _fourStep0 = ntsc4Step0;
  int _fourStep1 = ntsc4Step1;
  int _fourStep2 = ntsc4Step2;
  int _fourStep3 = ntsc4Step3;

  int _fiveStep0 = ntsc5Step0;
  int _fiveStep1 = ntsc5Step1;
  int _fiveStep2 = ntsc5Step2;
  int _fiveStep3 = ntsc5Step3;
  int _fiveStep4 = ntsc5Step4;

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

  // we don't need a getter
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    switch (region) {
      case Region.ntsc:
        _fourStep0 = ntsc4Step0;
        _fourStep1 = ntsc4Step1;
        _fourStep2 = ntsc4Step2;
        _fourStep3 = ntsc4Step3;

        _fiveStep0 = ntsc5Step0;
        _fiveStep1 = ntsc5Step1;
        _fiveStep2 = ntsc5Step2;
        _fiveStep3 = ntsc5Step3;
        _fiveStep4 = ntsc5Step4;
      case Region.pal:
        _fourStep0 = pal4Step0;
        _fourStep1 = pal4Step1;
        _fourStep2 = pal4Step2;
        _fourStep3 = pal4Step3;

        _fiveStep0 = pal5Step0;
        _fiveStep1 = pal5Step1;
        _fiveStep2 = pal5Step2;
        _fiveStep3 = pal5Step3;
        _fiveStep4 = pal5Step4;
    }
  }

  void reset() {
    counter = 0;

    fiveStep = false;

    interrupt = false;
    interruptInhibit = false;
  }

  int getStatus({bool disableSideEffects = false}) {
    final value = interrupt ? 1 : 0;

    if (!disableSideEffects) {
      // TODO
      // If an interrupt flag was set at the same moment of the read,
      // it will read back as 1 but it will not be cleared.
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
    if (counter == _fourStep0) {
      _doFrameCounter4Step(0);
    } else if (counter == _fourStep1) {
      _doFrameCounter4Step(1);
    } else if (counter == _fourStep2) {
      _doFrameCounter4Step(2);
    } else if (counter == _fourStep3) {
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

          apu.bus.triggerIrq(IrqSource.apuFrameCounter);
        }
    }
  }

  void _stepFrameCounter5StepMode() {
    if (counter == _fiveStep0) {
      _doFrameCounter5Step(0);
    } else if (counter == _fiveStep1) {
      _doFrameCounter5Step(1);
    } else if (counter == _fiveStep2) {
      _doFrameCounter5Step(2);
    } else if (counter == _fiveStep3) {
      _doFrameCounter5Step(3);
    } else if (counter == _fiveStep4) {
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
