import 'package:flutter_riverpod/flutter_riverpod.dart';

const buildId = String.fromEnvironment('NESD_BUILD_ID');

final buildIdProvider = Provider<String>((ref) => buildId);
