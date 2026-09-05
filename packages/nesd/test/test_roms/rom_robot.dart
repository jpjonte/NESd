import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

@immutable
class RomResult {
  const RomResult({required this.status, required this.text});

  final int status;
  final String text;

  bool get passed => status == 0;

  @override
  String toString() => 'status $status: $text';
}

class RomRobot {
  static const _statusAddress = 0x6000;
  static const _statusRunning = 0x80;
  static const _statusNeedsReset = 0x81;
  static const _maxResultText = 4096;

  RomRobot(this.path) {
    final file = File(path);

    final cartridgeFactory = CartridgeFactory(database: MockNesDatabase());

    final cartridge = cartridgeFactory.fromFile(
      FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
      file.readAsBytesSync(),
    )..databaseEntry = null;

    nes = NES(cartridge: cartridge, eventBus: EventBus())..reset();
  }

  final String path;

  late final NES nes;

  void buttonUp(int controller, NesButton button) {
    nes.bus.buttonUp(controller, button);
  }

  void buttonDown(int controller, NesButton button) {
    nes.bus.buttonDown(controller, button);
  }

  void runUntil(
    int breakAddress, {
    void Function(NES)? expect,
    int? maxCycles,
  }) {
    var cycles = 0;

    while (true) {
      nes.step();

      nes.apu.sampleIndex = 0;

      expect?.call(nes);

      cycles++;

      if (nes.cpu.PC == breakAddress) {
        break;
      }

      if (maxCycles != null && cycles >= maxCycles) {
        throw Exception('Max cycles reached');
      }
    }
  }

  void runFrames(int count) {
    final target = nes.ppu.frames + count;

    while (nes.ppu.frames < target) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }
  }

  RomResult runUntilResult({int maxFrames = 2400}) {
    var sawRunning = false;

    for (var frame = 0; frame < maxFrames; frame++) {
      runFrames(1);

      if (!_hasResultSignature()) {
        continue;
      }

      final status = _peek(_statusAddress);

      if (status == _statusNeedsReset) {
        if (sawRunning) {
          _pressReset();

          sawRunning = false;
        }

        continue;
      }

      if (status >= _statusRunning) {
        sawRunning = true;

        continue;
      }

      if (sawRunning) {
        return RomResult(status: status, text: _resultText());
      }
    }

    throw StateError(
      'ROM reported no result within $maxFrames frames '
      '(status ${_peek(_statusAddress)}): ${_resultText()}',
    );
  }

  void _pressReset() {
    runFrames(8);

    nes.softReset();
  }

  bool _hasResultSignature() =>
      _peek(0x6001) == 0xde && _peek(0x6002) == 0xb0 && _peek(0x6003) == 0x61;

  String _resultText() {
    final buffer = StringBuffer();

    for (var offset = 0; offset < _maxResultText; offset++) {
      final char = _peek(0x6004 + offset);

      if (char == 0) {
        break;
      }

      buffer.writeCharCode(char);
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _peek(int address) => nes.bus.cpuRead(address, disableSideEffects: true);

  /// FNV-1a over the current framebuffer; relies on Dart VM 64-bit
  /// wrapping int arithmetic (tests run on the VM only).
  int framebufferHash() {
    final pixels = nes.ppu.frameBuffer.pixels;

    var hash = 0xcbf29ce484222325;

    for (var i = 0; i < pixels.length; i++) {
      hash = (hash ^ pixels[i]) * 0x100000001b3;
    }

    return hash;
  }
}
