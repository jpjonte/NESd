import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

@immutable
class RomResult {
  const RomResult({required this.status, required this.text});

  static RomResult? tryFromScreen(String text) {
    final word = _wordVerdict.firstMatch(text);

    if (word != null) {
      final code = word.group(2);

      return RomResult(
        status: word.group(1) != null
            ? 0
            : code == null
            ? 1
            : int.parse(code),
        text: _collapse(text),
      );
    }

    final hex = _hexVerdict.firstMatch(text);

    if (hex == null) {
      return null;
    }

    final code = int.parse(hex.group(1)!, radix: 16);

    return RomResult(status: code == 1 ? 0 : code, text: _collapse(text));
  }

  static final _wordVerdict = RegExp(
    r'\b(?:(PASSED)|FAILED(?::? #(\d+))?)\b',
    caseSensitive: false,
  );

  static final _hexVerdict = RegExp(r'^\$([0-9A-F]{2})$', multiLine: true);

  final int status;
  final String text;

  bool get passed => status == 0;

  @override
  String toString() => 'status $status: $text';
}

String _collapse(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

class RomRobot {
  static const _statusAddress = 0x6000;
  static const _statusRunning = 0x80;
  static const _statusNeedsReset = 0x81;
  static const _maxResultText = 4096;

  RomRobot(this.path, {Region region = Region.ntsc}) {
    final file = File(path);

    final cartridgeFactory = CartridgeFactory(database: MockNesDatabase());

    final cartridge = cartridgeFactory.fromFile(
      FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
      file.readAsBytesSync(),
    )..databaseEntry = null;

    nes = NES(cartridge: cartridge, eventBus: EventBus())
      ..region = region
      ..reset();
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

  RomResult runUntilScreenResult({int maxFrames = 2400}) {
    for (var frame = 0; frame < maxFrames; frame++) {
      runFrames(1);

      final result = RomResult.tryFromScreen(screenText());

      if (result != null) {
        return result;
      }
    }

    throw StateError(
      'ROM drew no verdict within $maxFrames frames: '
      '${_collapse(screenText())}',
    );
  }

  String runUntilScreenCrc({int maxFrames = 2400}) {
    for (var frame = 0; frame < maxFrames; frame++) {
      runFrames(1);

      final crc = crcOnScreen(screenText());

      if (crc != null) {
        return crc;
      }
    }

    throw StateError(
      'ROM printed no CRC within $maxFrames frames: '
      '${_collapse(screenText())}',
    );
  }

  static String? crcOnScreen(String text) =>
      _crcLine.firstMatch(text)?.group(1);

  static final _crcLine = RegExp(r'^([0-9A-F]{8})$', multiLine: true);

  String screenText() {
    final buffer = StringBuffer();

    for (var row = 0; row < 30; row++) {
      final line = StringBuffer();

      for (var column = 0; column < 32; column++) {
        final tile = nes.bus.ppuRead(
          0x2000 + row * 32 + column,
          disableSideEffects: true,
        );

        line.writeCharCode(tile >= 0x20 && tile < 0x7f ? tile : 0x20);
      }

      final text = line.toString().trim();

      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }

    return buffer.toString();
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

    return _collapse(buffer.toString());
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
