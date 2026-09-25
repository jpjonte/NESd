import 'package:nesd/exception/rom_download_failed.dart';
import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';

RomFetcher createRomFetcher() => const _UnsupportedRomFetcher();

class _UnsupportedRomFetcher implements RomFetcher {
  const _UnsupportedRomFetcher();

  @override
  Future<RomResponse> fetch(Uri url) async =>
      throw RomDownloadFailed('Loading a ROM from a URL needs the web build');
}
