import 'package:flutter/foundation.dart';
import 'package:nesd/exception/invalid_rom_link.dart';
import 'package:nesd/exception/rom_download_failed.dart';
import 'package:nesd/exception/rom_too_large.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_downloader.g.dart';

const maxRomLinkBytes = 16 * 1024 * 1024;

@riverpod
RomFetcher romFetcher(Ref ref) => createRomFetcher();

@riverpod
RomDownloader romDownloader(Ref ref) =>
    RomDownloader(fetcher: ref.watch(romFetcherProvider));

@immutable
class DownloadedRom {
  const DownloadedRom({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class RomDownloader {
  RomDownloader({required this.fetcher, this.maxBytes = maxRomLinkBytes});

  final RomFetcher fetcher;
  final int maxBytes;

  Future<DownloadedRom> download(Uri url) async {
    final segments = url.pathSegments;
    final name = segments.isEmpty ? '' : segments.last;

    if (name.isEmpty) {
      throw InvalidRomLink('$url does not name a file');
    }

    if (!romPickerExtensions.contains(fileExtension(name))) {
      throw UnsupportedFileType(fileExtension(name));
    }

    final response = await fetcher.fetch(url);

    if (response.status < 200 || response.status > 299) {
      throw RomDownloadFailed(
        'Could not download $url: the server answered ${response.status}',
      );
    }

    if ((response.contentLength ?? 0) > maxBytes) {
      throw RomTooLarge(url: url, maxBytes: maxBytes);
    }

    final bytes = await response.bytes();

    if (bytes.length > maxBytes) {
      throw RomTooLarge(url: url, maxBytes: maxBytes);
    }

    return DownloadedRom(name: name, bytes: bytes);
  }
}
