import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nesd/ui/cheats/cheats_screen.dart';
import 'package:nesd/ui/emulator/emulator_screen.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/log/log_screen.dart';
import 'package:nesd/ui/main_menu/main_screen.dart';
import 'package:nesd/ui/menu/menu_screen.dart';
import 'package:nesd/ui/menu/tools_screen.dart';
import 'package:nesd/ui/save_states/save_states_screen.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_screen.dart';
import 'package:nesd/ui/settings/settings_screen.dart';

part 'router.gr.dart';

final routerProvider = ChangeNotifierProvider(
  (ref) => Router(
    isNesRunning: () => ref.read(nesStateProvider.notifier).nes != null,
  ),
);

/// Redirects to the main menu when no emulator is running.
class NesRunningGuard extends AutoRouteGuard {
  NesRunningGuard({required this.isNesRunning});

  final bool Function() isNesRunning;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isNesRunning()) {
      resolver.next();

      return;
    }

    if (router.stack.isEmpty) {
      resolver.redirectUntil(const MainRoute());
    } else {
      // assume MainRoute is already present
      resolver.next(false);
    }
  }
}

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class Router extends RootStackRouter {
  Router({bool Function()? isNesRunning})
    : _nesRunningGuard = NesRunningGuard(
        isNesRunning: isNesRunning ?? (() => false),
      );

  final NesRunningGuard _nesRunningGuard;

  @override
  late final List<AutoRoute> routes = [
    CustomRoute(
      page: MainRoute.page,
      path: '/',
      initial: true,
      transitionsBuilder: TransitionsBuilders.noTransition,
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    ),
    CustomRoute(
      page: EmulatorRoute.page,
      path: '/emulator',
      guards: [_nesRunningGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    ),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: TouchEditorRoute.page, path: '/touch_editor'),
    AutoRoute(page: FilePickerRoute.page, path: '/file_picker'),
    AutoRoute(
      page: CheatsRoute.page,
      path: '/cheats',
      guards: [_nesRunningGuard],
    ),
    AutoRoute(
      page: ToolsRoute.page,
      path: '/tools',
      guards: [_nesRunningGuard],
    ),
    AutoRoute(page: LogRoute.page, path: '/logs'),
    CustomRoute(
      page: MenuRoute.page,
      path: '/menu',
      guards: [_nesRunningGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
      opaque: false,
      customRouteBuilder: <T>(context, child, page) {
        return PageRouteBuilder<T>(
          fullscreenDialog: page.fullscreenDialog,
          opaque: page.opaque,
          settings: page,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          pageBuilder: (_, _, _) => child,
        );
      },
    ),
    AutoRoute(page: SaveStatesRoute.page, path: '/save_states'),
  ];
}
