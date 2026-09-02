import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/apu/apu_mix.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/apu/tables.dart';

import '../cartridge/mapper/mmc5_harness.dart';
import '../cartridge/mapper/namco163_harness.dart';

void _run(APU apu, void Function() stepMapper) {
  for (var i = 0; i < 256; i++) {
    apu.step();
    stepMapper();
  }
}

typedef _DmcRun = ({int level, double sample});

_DmcRun _dmcLevelAtGain(double gain) {
  final mapper = buildMmc5();
  final apu = mapper.bus.apu
    ..reset()
    ..mixer = MixerSettings(dmc: gain)
    ..writeRegister(0x4011, 0x7f);

  _run(apu, mapper.step);

  return (level: apu.dmc.output, sample: apu.sampleBuffer[apu.sampleIndex - 1]);
}

void main() {
  test('the mixer defaults to unity gain', () {
    final apu = buildMmc5().bus.apu;

    expect(apu.mixer, const MixerSettings());
  });

  test('a muted core channel is silent in the emitted samples', () {
    expect(_dmcLevelAtGain(1).sample, greaterThan(0));
    expect(_dmcLevelAtGain(0).sample, 0);
  });

  test('a core channel gain scales that channel', () {
    final full = _dmcLevelAtGain(1);
    final half = _dmcLevelAtGain(0.5);

    expect(half.sample, greaterThan(0));
    expect(half.sample, lessThan(full.sample));

    expect(half.sample, closeTo(tndMix(half.level * 0.5), 1e-6));
    expect(full.sample, closeTo(tndMix(full.level.toDouble()), 1e-6));
  });

  group('expansion gains are routed per chip', () {
    test('the MMC5 gain mutes MMC5 audio', () {
      final mapper = buildMmc5();
      final apu = mapper.bus.apu
        ..reset()
        ..mixer = const MixerSettings(mmc5: 0);

      mapper.cpuWrite(0x5011, 0xff);

      _run(apu, mapper.step);

      expect(apu.sampleBuffer[1], 0);
    });

    test('the Namco 163 gain leaves MMC5 audio alone', () {
      final mapper = buildMmc5();
      final apu = mapper.bus.apu
        ..reset()
        ..mixer = const MixerSettings(namco163: 0);

      mapper.cpuWrite(0x5011, 0xff);

      _run(apu, mapper.step);

      expect(apu.sampleBuffer[1], closeTo(tndTable[127], 1e-6));
    });

    test('the Namco 163 gain mutes Namco 163 audio', () {
      final mapper = buildNamco163();
      final apu = mapper.bus.apu
        ..reset()
        ..mixer = const MixerSettings(namco163: 0);

      mapper.audio.ram[0x7f] = 0x0f;
      mapper.audio.ram[0x7c] = 0xfc;
      mapper.audio.ram[0x78] = 0x00;
      mapper.audio.ram[0x7a] = 0x01;

      _run(apu, mapper.step);

      expect(apu.sampleBuffer[1], 0);
    });

    test('the MMC5 gain leaves Namco 163 audio alone', () {
      final mapper = buildNamco163();
      final apu = mapper.bus.apu
        ..reset()
        ..mixer = const MixerSettings(mmc5: 0);

      mapper.audio.ram[0x7f] = 0x0f;
      mapper.audio.ram[0x7c] = 0xfc;
      mapper.audio.ram[0x78] = 0x00;
      mapper.audio.ram[0x7a] = 0x01;

      _run(apu, mapper.step);

      expect(apu.sampleBuffer[1], lessThan(0));
    });
  });

  test('a mixer set before reset survives it', () {
    final mapper = buildMmc5();
    final apu = mapper.bus.apu
      ..mixer = const MixerSettings(mmc5: 0)
      ..reset();

    mapper.cpuWrite(0x5011, 0xff);

    _run(apu, mapper.step);

    expect(apu.sampleBuffer[1], 0);
  });
}
