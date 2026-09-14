import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

enum DownloadPlatform(final String label) {
  macos('macOS'),
  windows('Windows'),
  linux('Linux'),
  android('Android'),
}

@immutable
class const DownloadAsset({
  required final DownloadPlatform platform,
  required final String label,
  required final Uri url,
});

@immutable
class const _AssetRule(
  final String suffix,
  final DownloadPlatform platform,
  final String label,
);

const _rules = [
  _AssetRule('.macos-universal.dmg', DownloadPlatform.macos, '.dmg'),
  _AssetRule('.windows-x64.zip', DownloadPlatform.windows, '.zip'),
  _AssetRule('.linux-x64.AppImage', DownloadPlatform.linux, 'AppImage (x64)'),
  _AssetRule(
    '.linux-arm64.AppImage',
    DownloadPlatform.linux,
    'AppImage (arm64)',
  ),
  _AssetRule('.linux-x64.deb', DownloadPlatform.linux, '.deb (x64)'),
  _AssetRule('.linux-arm64.deb', DownloadPlatform.linux, '.deb (arm64)'),
  _AssetRule('.linux-x64.rpm', DownloadPlatform.linux, '.rpm (x64)'),
  _AssetRule('.linux-arm64.rpm', DownloadPlatform.linux, '.rpm (arm64)'),
  _AssetRule('.linux-x64.flatpak', DownloadPlatform.linux, '.flatpak (x64)'),
  _AssetRule(
    '.linux-arm64.flatpak',
    DownloadPlatform.linux,
    '.flatpak (arm64)',
  ),
  _AssetRule('.android.apk', DownloadPlatform.android, '.apk'),
];

@immutable
class const ReleaseManifest({
  required final String version,
  required final Uri releaseUrl,
  required final List<DownloadAsset> assets,
  final DateTime? publishedAt,
}) {
  factory fromJson(Map<String, Object?> json) {
    final version = json['tag_name'];
    final htmlUrl = json['html_url'];
    final rawAssets = json['assets'];
    final rawPublishedAt = json['published_at'];

    if (version is! String || htmlUrl is! String || rawAssets is! List) {
      throw const FormatException(
        'release json needs tag_name, html_url and an assets list',
      );
    }

    final named = <String, Uri>{};

    for (final raw in rawAssets) {
      if (raw is! Map || raw['name'] is! String) {
        throw const FormatException('release asset without a name');
      }

      final url = raw['browser_download_url'];

      if (url is! String) {
        throw FormatException(
          'release asset ${raw['name']} has no browser_download_url',
        );
      }

      named[raw['name'] as String] = Uri.parse(url);
    }

    final assets = [
      for (final rule in _rules)
        for (final MapEntry(key: name, value: url) in named.entries)
          if (name.endsWith(rule.suffix))
            DownloadAsset(platform: rule.platform, label: rule.label, url: url),
    ];

    if (assets.isEmpty) {
      throw FormatException(
        'no release asset matched the suffix table for $version',
      );
    }

    return ReleaseManifest(
      version: version,
      releaseUrl: Uri.parse(htmlUrl),
      assets: assets,
      publishedAt: rawPublishedAt is String
          ? DateTime.tryParse(rawPublishedAt)
          : null,
    );
  }

  String? get releaseDate {
    if (publishedAt case final date?) {
      return DateFormat('d MMMM y').format(date);
    }

    return null;
  }

  List<DownloadAsset> forPlatform(DownloadPlatform platform) => [
    for (final asset in assets)
      if (asset.platform == platform) asset,
  ];
}
