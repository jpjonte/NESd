import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

base class FakePlatformFile extends PlatformFile {
  FakePlatformFile({
    required this.name,
    required this.path,
    this.size = 0,
    this.bytes,
  });

  @override
  final String name;

  @override
  final String path;

  final int size;

  final Uint8List? bytes;

  @override
  Future<int> length() async => size;

  @override
  Stream<Uint8List> readAsByteStream() {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = this.bytes;

    if (bytes == null) {
      throw UnimplementedError();
    }

    return bytes;
  }

  @override
  Uri get uri => Uri.parse(path);

  @override
  XFile get xFile => throw UnimplementedError();
}
