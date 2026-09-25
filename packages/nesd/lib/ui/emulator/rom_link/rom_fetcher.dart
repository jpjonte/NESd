import 'package:flutter/foundation.dart';

export 'package:nesd/ui/emulator/rom_link/rom_fetcher_native.dart'
    if (dart.library.js_interop) 'package:nesd/ui/emulator/rom_link/rom_fetcher_web.dart';

// ignore: one_member_abstracts
abstract interface class RomFetcher {
  Future<RomResponse> fetch(Uri url);
}

@immutable
class RomResponse {
  const RomResponse({
    required this.status,
    required this.bytes,
    this.contentLength,
  });

  final int status;

  final int? contentLength;

  final Future<Uint8List> Function() bytes;
}
