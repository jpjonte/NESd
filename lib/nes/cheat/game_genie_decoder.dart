// ignore_for_file: avoid_classes_with_only_static_members

import 'package:nesd/nes/cheat/cheat.dart';

// Game Genie decoder for NES
class GameGenieDecoder {
  // Game Genie character mapping
  static const _charMap = {
    'A': 0x0,
    'P': 0x1,
    'Z': 0x2,
    'L': 0x3,
    'G': 0x4,
    'I': 0x5,
    'T': 0x6,
    'Y': 0x7,
    'E': 0x8,
    'O': 0x9,
    'X': 0xA,
    'U': 0xB,
    'K': 0xC,
    'S': 0xD,
    'V': 0xE,
    'N': 0xF,
  };

  static Cheat? decode(String code, {String? name}) {
    final cleaned = code.toUpperCase().replaceAll(
      RegExp('[^APZLGITYEOXUKSVN]'),
      '',
    );

    if (cleaned.length != 6 && cleaned.length != 8) {
      return null;
    }

    try {
      final values = cleaned.split('').map((c) => _charMap[c]!).toList();

      int address;
      int value;
      int? compareValue;

      if (cleaned.length == 6) {
        // 6-character code (no compare value)
        address = _decode6Address(values);
        value = _decode6Value(values);
      } else {
        // 8-character code (with compare value)
        address = _decode8Address(values);
        value = _decode8Value(values);
        compareValue = _decode8Compare(values);
      }

      return Cheat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? code,
        type: CheatType.gameGenie,
        address: address,
        value: value,
        compareValue: compareValue,
      );
    } on Exception {
      return null;
    }
  }

  static int _decode6Address(List<int> values) {
    // NES Game Genie 6-character address decoding
    // Bit layout (n = char position 0-5, bits 0-3):
    // Address: n3:210 n5:210 n4:3 n2:210 n1:3 n4:210 n3:3
    final n1 = values[1];
    final n2 = values[2];
    final n3 = values[3];
    final n4 = values[4];
    final n5 = values[5];

    return 0x8000 |
        ((n3 & 0x7) << 12) |
        ((n5 & 0x7) << 8) |
        ((n4 & 0x8) << 8) |
        ((n2 & 0x7) << 4) |
        ((n1 & 0x8) << 4) |
        (n4 & 0x7) |
        (n3 & 0x8);
  }

  static int _decode6Value(List<int> values) {
    // NES Game Genie 6-character value decoding
    // Value: n1:210 n0:3 n0:210 n5:3
    final n0 = values[0];
    final n1 = values[1];
    final n5 = values[5];

    return ((n1 & 0x7) << 4) | ((n0 & 0x8) << 4) | (n0 & 0x7) | (n5 & 0x8);
  }

  static int _decode8Address(List<int> values) {
    // Extract address bits from 8-character code
    // Same format as 6-character for address
    return 0x8000 |
        ((values[3] & 0x7) << 12) |
        ((values[5] & 0x7) << 8) |
        ((values[4] & 0x8) << 8) |
        ((values[2] & 0x7) << 4) |
        ((values[1] & 0x8) << 4) |
        (values[4] & 0x7) |
        (values[3] & 0x8);
  }

  static int _decode8Value(List<int> values) {
    // Extract value bits from 8-character code
    return ((values[1] & 0x7) << 4) |
        ((values[0] & 0x8) << 4) |
        (values[0] & 0x7) |
        (values[7] & 0x8);
  }

  static int _decode8Compare(List<int> values) {
    // Extract compare value bits from 8-character code
    return ((values[7] & 0x7) << 4) |
        ((values[6] & 0x8) << 4) |
        (values[6] & 0x7) |
        (values[5] & 0x8);
  }

  static bool isValidCode(String code) {
    final cleaned = code.toUpperCase().replaceAll(
      RegExp('[^APZLGITYEOXUKSVN]'),
      '',
    );

    return (cleaned.length == 6 || cleaned.length == 8) &&
        cleaned.split('').every((c) => _charMap.containsKey(c));
  }
}
