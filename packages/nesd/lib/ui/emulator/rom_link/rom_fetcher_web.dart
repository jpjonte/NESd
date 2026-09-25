import 'dart:js_interop';
import 'dart:typed_data';

import 'package:nesd/exception/rom_download_failed.dart';
import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';
import 'package:web/web.dart' as web;

RomFetcher createRomFetcher() => const _BrowserRomFetcher();

class _BrowserRomFetcher implements RomFetcher {
  const _BrowserRomFetcher();

  @override
  Future<RomResponse> fetch(Uri url) async {
    final web.Response response;

    try {
      response = await web.window.fetch(url.toString().toJS).toDart;
    } on Object {
      throw RomDownloadFailed(
        'Could not download $url. The server is unreachable or does not '
        'allow cross-origin requests',
      );
    }

    final contentLength = response.headers.get('content-length');

    return RomResponse(
      status: response.status,
      contentLength: contentLength == null ? null : int.tryParse(contentLength),
      bytes: () => _read(url, response),
    );
  }

  Future<Uint8List> _read(Uri url, web.Response response) async {
    try {
      final buffer = await response.arrayBuffer().toDart;

      return buffer.toDart.asUint8List();
    } on Object {
      throw RomDownloadFailed('Download of $url was interrupted');
    }
  }
}
