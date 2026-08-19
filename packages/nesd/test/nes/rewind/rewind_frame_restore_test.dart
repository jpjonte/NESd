import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _NullDatabase implements NesDatabase {
  const _NullDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

NES _buildNes(EventBus eventBus) {
  const path = '../../roms/test/spritecans-2011/spritecans.nes';
  final bytes = File(path).readAsBytesSync();
  const factory = CartridgeFactory(database: _NullDatabase());

  final cartridge = factory.fromFile(
    const FilesystemFile(
      path: path,
      name: 'spritecans.nes',
      type: FilesystemFileType.file,
    ),
    bytes,
  )..databaseEntry = null;

  return NES(cartridge: cartridge, eventBus: eventBus)..reset();
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

int _checksum(Uint8List pixels) {
  var hash = 0x811c9dc5;

  for (final byte in pixels) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }

  return hash;
}

typedef _Presented = ({int frame, int checksum});

void main() {
  test('rewind presents the image that was shown at that frame', () async {
    final eventBus = EventBus();
    final nes = _buildNes(eventBus)..rewindEnabled = true;

    final presented = <_Presented>[];
    final drainCounts = <int>[];

    final subscription = eventBus.stream.listen((event) {
      if (event is! FrameNesEvent) {
        return;
      }

      final taken = <Uint8List>[];

      for (
        var buffer = nes.ppu.frameBuffer.takeReadyBuffer();
        buffer != null;
        buffer = nes.ppu.frameBuffer.takeReadyBuffer()
      ) {
        taken.add(buffer);
      }

      drainCounts.add(taken.length);

      if (taken.isEmpty) {
        return;
      }

      presented.add((frame: event.frame, checksum: _checksum(taken.last)));

      for (final buffer in taken) {
        nes.ppu.frameBuffer.releaseDisplayBuffer(buffer);
      }
    });

    unawaited(nes.run());

    await _waitUntil(() => presented.length >= 40);

    nes.rewind = true;

    await _waitUntil(() => presented.length >= 60);

    nes
      ..rewind = false
      ..stop();

    await _waitUntil(() => !nes.inLoop);
    await subscription.cancel();

    expect(drainCounts, everyElement(1));

    final split = presented.indexed
        .skip(1)
        .firstWhere(
          (e) => e.$2.frame < presented[e.$1 - 1].frame,
          orElse: () => (-1, (frame: -1, checksum: -1)),
        )
        .$1;

    expect(split, greaterThan(0), reason: 'rewind never ran');

    final forward = <int, int>{
      for (final entry in presented.take(split)) entry.frame: entry.checksum,
    };
    final rewound = presented.skip(split).toList();

    expect(rewound, isNotEmpty);
    expect(
      forward.values.toSet(),
      hasLength(greaterThan(3)),
      reason: 'the ROM must animate for this comparison to mean anything',
    );

    for (final entry in rewound) {
      expect(
        forward,
        contains(entry.frame),
        reason: 'rewind presented frame ${entry.frame}, never played forward',
      );
      expect(
        entry.checksum,
        forward[entry.frame],
        reason: 'frame ${entry.frame} was restored with a different image',
      );
    }
  });

  test('a captured state carries the frame that was just presented', () {
    final eventBus = EventBus();
    final nes = _buildNes(eventBus)..on = true;

    while (nes.ppu.frames < 30) {
      final target = nes.ppu.frames + 1;

      while (nes.ppu.frames < target) {
        nes.step();
      }

      nes.ppu.frameBuffer.swap();
    }

    final target = nes.ppu.frames + 1;

    while (nes.ppu.frames < target) {
      nes.step();
    }

    final presented = Uint8List.fromList(nes.ppu.frameBuffer.pixels);

    expect(
      presented.any((byte) => byte != 0),
      isTrue,
      reason: 'a blank frame would make this comparison vacuous',
    );

    nes.ppu.frameBuffer.swap();

    final restored = NESState.fromBytes(nes.state!.serialize());

    expect(
      _checksum(restored.ppuState.frameBuffer.pixels),
      _checksum(presented),
    );
  });
}
