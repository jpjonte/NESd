import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_system/native_filesystem.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('nesd_modified');

    addTearDown(() => directory.deleteSync(recursive: true));
  });

  test('list reports each file modification time', () async {
    final stamp = DateTime(2024, 5, 6, 7, 8, 9);

    File('${directory.path}/a.nes')
      ..writeAsBytesSync([0])
      ..setLastModifiedSync(stamp);

    final listed = await NativeFilesystem().list(directory.path);

    expect(listed.single.modified, stamp);
  });

  test('directories carry no modification time', () async {
    Directory('${directory.path}/sub').createSync();

    final listed = await NativeFilesystem().list(directory.path);

    expect(listed.single.modified, isNull);
  });
}
