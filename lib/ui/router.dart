import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/main_screen.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/menu/menu_screen.dart';
import 'package:nesd/ui/settings/settings_screen.dart';

part 'router.gr.dart';

final routerProvider = ChangeNotifierProvider((ref) => Router());

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        CustomRoute(
          page: MainRoute.page,
          path: '/',
          initial: true,
          transitionsBuilder: TransitionsBuilders.noTransition,
          durationInMilliseconds: 0,
          reverseDurationInMilliseconds: 0,
        ),
        AutoRoute(page: SettingsRoute.page, path: '/settings'),
        AutoRoute(page: FilePickerRoute.page, path: '/file_picker'),
        CustomRoute(
          page: MenuRoute.page,
          path: '/menu',
          transitionsBuilder: TransitionsBuilders.fadeIn,
          durationInMilliseconds: 200,
          reverseDurationInMilliseconds: 200,
          opaque: false,
        ),
      ];
}
