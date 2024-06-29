import 'package:auto_route/auto_route.dart';
import 'package:nes/ui/emulator/emulator_screen.dart';
import 'package:nes/ui/settings/settings_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';
part 'router.gr.dart';

@riverpod
Router router(RouterRef ref) => Router();

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class Router extends _$Router {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: EmulatorRoute.page, path: '/', initial: true),
        AutoRoute(page: SettingsRoute.page, path: '/settings'),
      ];
}
