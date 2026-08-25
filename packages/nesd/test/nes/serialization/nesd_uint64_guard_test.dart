import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ never uses binarize uint64 directly', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File ||
          !entity.path.endsWith('.dart') ||
          entity.path.endsWith('nesd_uint64.dart')) {
        continue;
      }

      if (RegExp(r'\buint64\b').hasMatch(entity.readAsStringSync())) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'use nesdUint64 instead; uint64 crashes on web',
    );
  });
}
