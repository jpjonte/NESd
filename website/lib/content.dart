import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:nesd_website/release.dart';

const siteUrl = 'https://nesd.jpj.dev';
const siteTitle = 'NESd: A cycle-accurate NES emulator';
const siteDescription =
    'NESd is a free and open-source NES emulator for macOS, Windows, Linux, '
    'Android and the web, with save states, rewind, gamepad and touch '
    'controls.';

const repoUrl = 'https://github.com/jpjonte/NESd';
const releasesUrl = '$repoUrl/releases';
const nightlyUrl = '$repoUrl/releases/tag/nightly';
const changelogUrl = '$repoUrl/blob/main/CHANGELOG.md';
const flatpakRepoUrl = 'https://jpjonte.github.io/flatpak/jpj.flatpakrepo';
const playUrl = '$siteUrl/play/';
const selfHostingUrl = '$repoUrl#self-hosting';
const contactEmail = 'nesd@jpj.dev';

/// keep in sync with README.md
const supportedGameCount = '3,070';

const features = [
  'Cycle-accurate CPU, PPU, APU',
  'Play in your browser',
  'NTSC and PAL',
  'Save states',
  'Rewind',
  'Battery-backed saves',
  'Gamepads',
  'Rebindable controls',
  'Touch controls',
  'CRT and smooth filters',
  'Game Genie cheats',
  'ZIP archives',
  'Debugger and execution log',
];

@immutable
class Screenshot {
  const Screenshot({required this.file, required this.alt});

  final String file;
  final String alt;
}

const screenshots = [
  Screenshot(file: 'smb.webp', alt: 'Super Mario Bros. running in NESd'),
  Screenshot(file: 'zelda.webp', alt: 'The Legend of Zelda running in NESd'),
  Screenshot(file: 'list.webp', alt: 'The NESd game library with thumbnails'),
  Screenshot(
    file: 'android_kirby.webp',
    alt: "Kirby's Adventure on Android with touch controls",
  ),
];

@immutable
class SiteInputs {
  const SiteInputs({required this.releaseJsonPath, required this.privacyPath});

  factory SiteInputs.fromEnvironment(
    Map<String, String> environment, {
    required String workingDirectory,
  }) {
    final pubspec = File('$workingDirectory/pubspec.yaml');

    if (!pubspec.existsSync() ||
        !pubspec.readAsStringSync().contains('name: nesd_website')) {
      throw StateError(
        'the website build must run from website/ (cwd is $workingDirectory)',
      );
    }

    return SiteInputs(
      releaseJsonPath:
          environment['NESD_RELEASE_JSON'] ??
          '$workingDirectory/build/release.json',
      privacyPath: '$workingDirectory/../PRIVACY.md',
    );
  }

  final String releaseJsonPath;
  final String privacyPath;
}

@immutable
class SiteContent {
  const SiteContent({required this.release, required this.privacyMarkdown});

  factory SiteContent.load(SiteInputs inputs) {
    final releaseFile = File(inputs.releaseJsonPath);

    if (!releaseFile.existsSync()) {
      throw StateError(
        '${inputs.releaseJsonPath} not found. run tool/fetch_release.sh first',
      );
    }

    final ReleaseManifest release;

    try {
      final json = jsonDecode(releaseFile.readAsStringSync());

      if (json is! Map<String, Object?>) {
        throw const FormatException('release json is not an object');
      }

      release = ReleaseManifest.fromJson(json);
    } on FormatException catch (e) {
      throw StateError(
        '${inputs.releaseJsonPath} is not a usable release manifest: '
        '${e.message}. Run tool/fetch_release.sh to refetch it',
      );
    }

    final privacyFile = File(inputs.privacyPath);

    if (!privacyFile.existsSync()) {
      throw StateError('${inputs.privacyPath} (PRIVACY.md) not found');
    }

    return SiteContent(
      release: release,
      privacyMarkdown: privacyFile.readAsStringSync(),
    );
  }

  final ReleaseManifest release;
  final String privacyMarkdown;
}
