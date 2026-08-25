import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

Future<StorageFilesystem> createStorageFilesystem() async =>
    NativeStorageFilesystem();
