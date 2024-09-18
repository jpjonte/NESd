// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [FilePickerScreen]
class FilePickerRoute extends PageRouteInfo<FilePickerRouteArgs> {
  FilePickerRoute({
    required String title,
    required String initialDirectory,
    required FilePickerType type,
    List<String> allowedExtensions = const [],
    void Function(Directory)? onChangeDirectory,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          FilePickerRoute.name,
          args: FilePickerRouteArgs(
            title: title,
            initialDirectory: initialDirectory,
            type: type,
            allowedExtensions: allowedExtensions,
            onChangeDirectory: onChangeDirectory,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'FilePickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FilePickerRouteArgs>();
      return FilePickerScreen(
        title: args.title,
        initialDirectory: args.initialDirectory,
        type: args.type,
        allowedExtensions: args.allowedExtensions,
        onChangeDirectory: args.onChangeDirectory,
        key: args.key,
      );
    },
  );
}

class FilePickerRouteArgs {
  const FilePickerRouteArgs({
    required this.title,
    required this.initialDirectory,
    required this.type,
    this.allowedExtensions = const [],
    this.onChangeDirectory,
    this.key,
  });

  final String title;

  final String initialDirectory;

  final FilePickerType type;

  final List<String> allowedExtensions;

  final void Function(Directory)? onChangeDirectory;

  final Key? key;

  @override
  String toString() {
    return 'FilePickerRouteArgs{title: $title, initialDirectory: $initialDirectory, type: $type, allowedExtensions: $allowedExtensions, onChangeDirectory: $onChangeDirectory, key: $key}';
  }
}

/// generated route for
/// [MainScreen]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainScreen();
    },
  );
}

/// generated route for
/// [MenuScreen]
class MenuRoute extends PageRouteInfo<void> {
  const MenuRoute({List<PageRouteInfo>? children})
      : super(
          MenuRoute.name,
          initialChildren: children,
        );

  static const String name = 'MenuRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MenuScreen();
    },
  );
}

/// generated route for
/// [SaveStatesScreen]
class SaveStatesRoute extends PageRouteInfo<SaveStatesRouteArgs> {
  SaveStatesRoute({
    required RomInfo romInfo,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          SaveStatesRoute.name,
          args: SaveStatesRouteArgs(
            romInfo: romInfo,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'SaveStatesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SaveStatesRouteArgs>();
      return SaveStatesScreen(
        romInfo: args.romInfo,
        key: args.key,
      );
    },
  );
}

class SaveStatesRouteArgs {
  const SaveStatesRouteArgs({
    required this.romInfo,
    this.key,
  });

  final RomInfo romInfo;

  final Key? key;

  @override
  String toString() {
    return 'SaveStatesRouteArgs{romInfo: $romInfo, key: $key}';
  }
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}

/// generated route for
/// [TouchEditorScreen]
class TouchEditorRoute extends PageRouteInfo<void> {
  const TouchEditorRoute({List<PageRouteInfo>? children})
      : super(
          TouchEditorRoute.name,
          initialChildren: children,
        );

  static const String name = 'TouchEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TouchEditorScreen();
    },
  );
}
