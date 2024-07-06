import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes/ui/common/focus_child.dart';
import 'package:nes/ui/common/focus_on_hover.dart';
import 'package:nes/ui/nesd_theme.dart';
import 'package:path/path.dart' as p;

enum FilePickerType {
  file,
  directory,
  any,
}

@RoutePage<String?>()
class FilePickerScreen extends HookWidget {
  const FilePickerScreen({
    required this.title,
    required this.initialDirectory,
    required this.type,
    this.allowedExtensions = const [],
    super.key,
  });

  final String title;
  final String initialDirectory;
  final FilePickerType type;
  final List<String> allowedExtensions;

  @override
  Widget build(BuildContext context) {
    final directory = useState(Directory(initialDirectory));
    final files = _getFiles(directory.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(8.0),
          child: FocusChild(
            autofocus: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      directory.value.path,
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge?.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return FocusOnHover(
                          child: ListTile(
                            leading: Icon(
                              Icons.drive_folder_upload_rounded,
                              color: nesdRed[500],
                            ),
                            title: const Text('Up a directory'),
                            onTap: () =>
                                directory.value = directory.value.parent,
                          ),
                        );
                      }

                      final file = files[index - 1];

                      return FocusOnHover(
                        child: ListTile(
                          leading: Icon(
                            file is Directory
                                ? Icons.folder
                                : Icons.videogame_asset,
                            color: nesdRed[500],
                          ),
                          enabled: file is Directory ||
                              allowedExtensions.isEmpty ||
                              allowedExtensions
                                  .contains(p.extension(file.path)),
                          title: Text(p.basename(file.path)),
                          onTap: () {
                            // TODO directory selection mode
                            if (file is Directory) {
                              directory.value = file;
                            } else {
                              context.router.maybePop(file.path);
                            }
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: files.length + 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FileSystemEntity> _getFiles(Directory directory) {
    final children = directory.listSync().where((entity) {
      if (p.basename(entity.path).startsWith('.')) {
        return false;
      }

      if (type == FilePickerType.directory) {
        return entity is Directory;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (a is Directory && b is! Directory) {
          return -1;
        } else if (a is! Directory && b is Directory) {
          return 1;
        }

        return a.path.compareTo(b.path);
      });

    return children;
  }
}
