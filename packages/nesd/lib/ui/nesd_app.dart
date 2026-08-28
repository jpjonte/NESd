import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/soak/soak_runner.dart';
import 'package:nesd/ui/splash/splash.dart';
import 'package:nesd/ui/theme/dark.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:nesd/ui/toast/toaster.dart';

/// Set by main.dart when startup degraded (e.g. persistent storage is
/// unavailable). Shown as a toast once the UI is up.
final startupWarningProvider = Provider<String?>((ref) => null);

/// Holds the long-lived services alive for the whole app lifetime.
class NesdApp extends ConsumerStatefulWidget {
  const NesdApp({super.key});

  @override
  ConsumerState<NesdApp> createState() => _NesdAppState();
}

class _NesdAppState extends ConsumerState<NesdApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      dismissSplash();

      if (ref.read(startupWarningProvider) case final warning?) {
        ref.read(toasterProvider).send(Toast.warning(warning));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(soakRunnerProvider)
      ..watch(actionHandlerProvider)
      ..watch(gamepadInputHandlerProvider)
      ..watch(toasterProvider)
      ..watch(nesControllerProvider)
      ..watch(romManagerProvider);

    return const _NesdMaterialApp();
  }
}

class _NesdMaterialApp extends ConsumerWidget {
  const _NesdMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observer = ref.watch(nesdRouterObserverProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: 'NESd',
      theme: nesdThemeLight,
      darkTheme: nesdThemeDark,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      routerConfig: router.config(navigatorObservers: () => [observer]),
    );
  }
}
