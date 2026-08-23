import 'dart:io';

import 'package:path/path.dart' as p;

const legacyLinuxApplicationId = 'dev.jpj.nesd';

Future<bool> migrateDevProfile({
  required Directory target,
  required Directory legacy,
}) async {
  if (!_isEmpty(target) || !legacy.existsSync()) {
    return false;
  }

  final staging = Directory('${target.path}.migrating');

  if (staging.existsSync()) {
    staging.deleteSync(recursive: true);
  }

  await _copyTree(legacy, staging);

  if (target.existsSync()) {
    target.deleteSync(recursive: true);
  }

  staging.renameSync(target.path);

  return true;
}

bool _isEmpty(Directory directory) =>
    !directory.existsSync() || directory.listSync().isEmpty;

Future<void> _copyTree(Directory from, Directory to) async {
  to.createSync(recursive: true);

  await for (final entity in from.list(recursive: true)) {
    final relative = p.relative(entity.path, from: from.path);
    final destination = p.join(to.path, relative);

    switch (entity) {
      case Directory():
        Directory(destination).createSync(recursive: true);
      case File():
        File(destination).parent.createSync(recursive: true);
        await entity.copy(destination);
      case _:
        break;
    }
  }
}
