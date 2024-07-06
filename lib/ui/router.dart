import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/emulator/emulator_screen.dart';
import 'package:nes/ui/file_picker/file_picker_screen.dart';
import 'package:nes/ui/settings/settings_screen.dart';

part 'router.gr.dart';

final routerProvider = ChangeNotifierProvider((ref) => Router());

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class Router extends _$Router {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: EmulatorRoute.page, path: '/', initial: true),
        AutoRoute(page: SettingsRoute.page, path: '/settings'),
        AutoRoute(page: FilePickerRoute.page, path: '/file_picker'),
      ];
}
