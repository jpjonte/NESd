import 'dart:typed_data';

import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';

class FakeRomFetcher implements RomFetcher {
  FakeRomFetcher(this._respond);

  FakeRomFetcher.bytes(Uint8List bytes)
    : _respond = ((_) async =>
          RomResponse(status: 200, bytes: () async => bytes));

  final Future<RomResponse> Function(Uri url) _respond;

  final requests = <Uri>[];

  @override
  Future<RomResponse> fetch(Uri url) {
    requests.add(url);

    return _respond(url);
  }
}
