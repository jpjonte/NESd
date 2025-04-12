import 'dart:async';
import 'dart:io';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final directory = Directory('/tmp/nesd');

  await directory.create();

  for (final file in directory.listSync()) {
    file.deleteSync(recursive: true);
  }

  await testMain();
}
