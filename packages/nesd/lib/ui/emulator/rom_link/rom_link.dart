import 'package:flutter/foundation.dart';
import 'package:nesd/exception/invalid_rom_link.dart';

@immutable
class RomLink {
  const RomLink({required this.url, this.slot, this.invalidSlot});

  factory RomLink.fromPage(Uri page) {
    final parameters = page.queryParameters;
    final rom = parameters['rom'];

    if (rom == null || rom.isEmpty) {
      throw InvalidRomLink('The link does not name a ROM');
    }

    final Uri url;

    try {
      url = page.resolve(rom);
    } on FormatException {
      throw InvalidRomLink('Invalid ROM URL: $rom');
    }

    if (url.scheme != 'http' && url.scheme != 'https') {
      throw InvalidRomLink('Unsupported ROM URL: $rom');
    }

    final slotParameter = parameters['slot'];
    final slot = slotParameter == null ? null : int.tryParse(slotParameter);
    final validSlot = slot != null && slot >= 0 && slot <= 9 ? slot : null;

    return RomLink(
      url: url,
      slot: validSlot,
      invalidSlot: validSlot == null ? slotParameter : null,
    );
  }

  final Uri url;

  final int? slot;

  final String? invalidSlot;
}
