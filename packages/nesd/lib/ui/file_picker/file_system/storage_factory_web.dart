import 'package:idb_shim/idb_browser.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';

Future<StorageFilesystem> createStorageFilesystem() =>
    WebStorageFilesystem.open(idbFactoryBrowser);
