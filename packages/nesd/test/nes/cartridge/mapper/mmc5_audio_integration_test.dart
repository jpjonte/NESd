import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

import 'mmc5_harness.dart';

void main() {
  late MMC5 mapper;

  setUp(() => mapper = buildMmc5());

  int irqLine() => mapper.bus.cpu.irq;

  group('register forwarding', () {
    test('the mapper exposes its audio as expansion audio', () {
      expect(mapper.expansionAudio, same(mapper.audio));
      expect(mapper.expansionAudio, isA<Mmc5Audio>());
    });

    test(r'writes to $5000-$5015 reach the audio chip', () {
      mapper
        ..cpuWrite(0x5015, 0x01)
        ..cpuWrite(0x5000, 0xdf)
        ..cpuWrite(0x5003, 0x18);

      expect(mapper.audio.pulse1.enabled, true);
      expect(mapper.audio.pulse1.output, 15);
    });

    test(r'$5011 writes reach the PCM channel', () {
      mapper.cpuWrite(0x5011, 0x55);

      expect(mapper.audio.pcmLevel, 0x55);
    });

    test(r'$5015 reads report length counter status', () {
      mapper
        ..cpuWrite(0x5015, 0x03)
        ..cpuWrite(0x5003, 0x18)
        ..cpuWrite(0x5007, 0x18);

      expect(mapper.cpuRead(0x5015), 0x03);
    });

    test('the mapper clocks the audio chip every CPU cycle', () {
      mapper
        ..cpuWrite(0x5015, 0x01)
        ..cpuWrite(0x5000, 0xdf)
        ..cpuWrite(0x5003, 0x18)
        ..step()
        ..step();

      expect(mapper.audio.cycles, 2);
      expect(mapper.audio.pulse1.dutyIndex, 7);
    });
  });

  group('PCM IRQ', () {
    test('a zero write asserts the mapper audio IRQ', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00);

      expect(irqLine() & IrqSource.mapperAudio.value, isNot(0));
    });

    test(r'reading $5010 acknowledges and clears the line', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00);

      expect(mapper.cpuRead(0x5010), 0x80);
      expect(irqLine() & IrqSource.mapperAudio.value, 0);
    });

    test('disabling the IRQ clears the line', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00)
        ..cpuWrite(0x5010, 0x00);

      expect(irqLine() & IrqSource.mapperAudio.value, 0);
    });

    test('a non-zero PCM write clears the line', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00)
        ..cpuWrite(0x5011, 0x7f);

      expect(irqLine() & IrqSource.mapperAudio.value, 0);
    });

    test('the PCM IRQ does not disturb a pending scanline IRQ', () {
      mapper.bus.triggerIrq(IrqSource.mapper);

      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00);

      expect(irqLine() & IrqSource.mapper.value, isNot(0));

      mapper.cpuRead(0x5010);

      expect(irqLine() & IrqSource.mapper.value, isNot(0));
      expect(irqLine() & IrqSource.mapperAudio.value, 0);
    });

    test(r'a $5204 read does not drop a pending PCM IRQ', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00)
        ..cpuRead(0x5204);

      expect(irqLine() & IrqSource.mapperAudio.value, isNot(0));
    });

    test('a side-effect-free read leaves the line asserted', () {
      mapper
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00)
        ..cpuRead(0x5010, disableSideEffects: true);

      expect(irqLine() & IrqSource.mapperAudio.value, isNot(0));
    });
  });
}
