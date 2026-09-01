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
const mappersUrl = '$repoUrl#supported-games-and-mappers';
const testersUrl = '$repoUrl/discussions/322';
const flatpakRepoUrl = 'https://jpjonte.github.io/flatpak/jpj.flatpakrepo';
const playUrl = '$siteUrl/play/';
const selfHostingUrl = '$repoUrl#self-hosting';
const contactEmail = 'nesd@jpj.dev';

/// keep in sync with README.md
const supportedGameCount = '3,169';

@immutable
class FeatureGroup {
  const FeatureGroup({required this.title, required this.features});

  final String title;
  final List<String> features;
}

const featureGroups = [
  FeatureGroup(
    title: 'Playing',
    features: [
      'Save states',
      'Rewind',
      'Battery-backed saves',
      'Game Genie cheats',
      'ZIP archives',
      'Fast forward',
    ],
  ),
  FeatureGroup(
    title: 'Controls and display',
    features: [
      'Gamepads',
      'Rebindable controls',
      'Touch controls',
      'Turbo buttons',
      'CRT and smooth filters',
      'Zapper light gun',
    ],
  ),
  FeatureGroup(
    title: 'Under the hood',
    features: [
      'Cycle-accurate CPU, PPU, APU',
      'NTSC and PAL timing',
      'Debugger and execution log',
    ],
  ),
];

@immutable
class RomSource {
  const RomSource({required this.label, required this.url, required this.note});

  final String label;
  final String url;
  final String note;
}

const romSources = [
  RomSource(
    label: 'itch.io homebrew',
    url: 'https://itch.io/games/tag-nes',
    note: 'New games, still being made today',
  ),
  RomSource(
    label: 'PDRoms',
    url:
        'https://pdroms.de/files/nintendo-nintendoentertainmentsystem-nes-'
        'famicom-fc',
    note: 'A long-running homebrew archive',
  ),
  RomSource(
    label: 'NESdev',
    url: 'https://www.nesdev.org/',
    note: 'The community behind most of it',
  ),
];

@immutable
class Screenshot {
  const Screenshot({
    required this.file,
    required this.alt,
    required this.caption,
    this.wide = false,
  });

  final String file;
  final String alt;
  final String caption;

  final bool wide;
}

const screenshots = [
  Screenshot(
    file: 'smb.webp',
    alt: 'Super Mario Bros. running in NESd',
    caption: 'Super Mario Bros.',
  ),
  Screenshot(
    file: 'battletoads.webp',
    alt: 'Battletoads running in NESd',
    caption: 'Battletoads',
  ),
  Screenshot(
    file: 'zelda.webp',
    alt: 'The Legend of Zelda running in NESd',
    caption: 'The Legend of Zelda',
  ),
  Screenshot(
    file: 'list.webp',
    alt: 'The NESd game library with thumbnails',
    caption: 'Your library, with thumbnails',
  ),
  Screenshot(
    file: 'android_kirby.webp',
    alt: "Kirby's Adventure on Android with touch controls",
    caption: 'Touch controls on Android',
    wide: true,
  ),
];

@immutable
class PlatformNote {
  const PlatformNote({required this.requirement, required this.firstLaunch});

  final String requirement;
  final String? firstLaunch;
}

const platformNotes = {
  DownloadPlatform.macos: PlatformNote(
    requirement: 'macOS 12 or later · Apple silicon and Intel',
    firstLaunch:
        'NESd is not signed by Apple, so macOS blocks the first launch. '
        'Open System Settings, go to "Privacy & Security", scroll to "Security"'
        ' and choose "Open Anyway".',
  ),
  DownloadPlatform.windows: PlatformNote(
    requirement: 'Windows 10 or later · 64-bit',
    firstLaunch:
        'Unzip anywhere and run NESd.exe. SmartScreen warns about unknown '
        'publishers: choose "More info", then "Run anyway".',
  ),
  DownloadPlatform.linux: PlatformNote(
    requirement: 'glibc 2.39 or later (Ubuntu 24.04+, Fedora 40+)',
    firstLaunch: 'On older distributions, install the Flatpak instead.',
  ),
  DownloadPlatform.android: PlatformNote(
    requirement: 'Android 7 or later',
    firstLaunch:
        'Install the APK. Android asks you to allow installs from your '
        'browser once.',
  ),
};

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
