// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

abstract class _$Router extends RootStackRouter {
  // ignore: unused_element
  _$Router({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    FilePickerRoute.name: (routeData) {
      final args = routeData.argsAs<FilePickerRouteArgs>();
      return AutoRoutePage<FileSystemFile?>(
        routeData: routeData,
        child: FilePickerScreen(
          title: args.title,
          initialDirectory: args.initialDirectory,
          type: args.type,
          allowedExtensions: args.allowedExtensions,
          onChangeDirectory: args.onChangeDirectory,
          key: args.key,
        ),
      );
    },
    MainRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MainScreen(),
      );
    },
    MenuRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MenuScreen(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsScreen(),
      );
    },
  };
}

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

  static const PageInfo<FilePickerRouteArgs> page =
      PageInfo<FilePickerRouteArgs>(name);
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

  static const PageInfo<void> page = PageInfo<void>(name);
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

  static const PageInfo<void> page = PageInfo<void>(name);
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

  static const PageInfo<void> page = PageInfo<void>(name);
}
