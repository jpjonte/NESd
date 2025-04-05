import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

class NesdApp extends ConsumerWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observer = ref.watch(routerObserverProvider.notifier);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NESd',
      theme: nesdThemeLight,
      darkTheme: nesdThemeDark,
      debugShowCheckedModeBanner: false,
      routerConfig: router.config(navigatorObservers: () => [observer]),
    );
  }
}
