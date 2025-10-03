import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

// This won't be called in normal operation, so we ignore it
// coverage:ignore-start
final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError();
});
// coverage:ignore-end
