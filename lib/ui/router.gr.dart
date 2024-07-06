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
    EmulatorRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const EmulatorScreen(),
      );
    },
    FilePickerRoute.name: (routeData) {
      final args = routeData.argsAs<FilePickerRouteArgs>();
      return AutoRoutePage<String?>(
        routeData: routeData,
        child: FilePickerScreen(
          title: args.title,
          initialDirectory: args.initialDirectory,
          type: args.type,
          allowedExtensions: args.allowedExtensions,
          key: args.key,
        ),
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
/// [EmulatorScreen]
class EmulatorRoute extends PageRouteInfo<void> {
  const EmulatorRoute({List<PageRouteInfo>? children})
      : super(
          EmulatorRoute.name,
          initialChildren: children,
        );

  static const String name = 'EmulatorRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [FilePickerScreen]
class FilePickerRoute extends PageRouteInfo<FilePickerRouteArgs> {
  FilePickerRoute({
    required String title,
    required String initialDirectory,
    required FilePickerType type,
    List<String> allowedExtensions = const [],
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          FilePickerRoute.name,
          args: FilePickerRouteArgs(
            title: title,
            initialDirectory: initialDirectory,
            type: type,
            allowedExtensions: allowedExtensions,
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
    this.key,
  });

  final String title;

  final String initialDirectory;

  final FilePickerType type;

  final List<String> allowedExtensions;

  final Key? key;

  @override
  String toString() {
    return 'FilePickerRouteArgs{title: $title, initialDirectory: $initialDirectory, type: $type, allowedExtensions: $allowedExtensions, key: $key}';
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

  static const PageInfo<void> page = PageInfo<void>(name);
}
