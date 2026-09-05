import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/features.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';

@RoutePage()
class MenuScreen extends ConsumerWidget {
  static const resumeKey = Key('resume');
  static const saveStatesKey = Key('saveStates');
  static const rewindTimelineKey = Key('rewindTimeline');
  static const resetGameKey = Key('resetGame');
  static const quitGameKey = Key('quitGame');
  static const settingsKey = Key('settings');
  static const toolsKey = Key('tools');

  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewindOn = ref.watch(
      settingsControllerProvider.select((settings) => settings.rewind),
    );

    return NesdScaffold(
      backgroundColor: Colors.black.withAlpha(200),
      appBar: AppBar(
        title: Text(
          'NESd',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: NesdButton(
                    key: resumeKey,
                    autofocus: true,
                    onPressed: () => ref
                        .read(routerProvider)
                        .navigate(const EmulatorRoute()),
                    child: const Text('Resume'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: saveStatesKey,
                    autofocus: true,
                    onPressed: () => ref
                        .read(routerProvider)
                        .navigate(
                          SaveStatesRoute(
                            romInfo: ref
                                .read(nesControllerProvider)
                                .nes!
                                .romInfo,
                          ),
                        ),
                    child: const Text('Save States'),
                  ),
                ),
                if (Features.rewind && rewindOn) ...[
                  const NesdVerticalDivider(),
                  Center(
                    child: NesdButton(
                      key: rewindTimelineKey,
                      onPressed: () => unawaited(_openRewindTimeline(ref)),
                      child: const Text('Rewind…'),
                    ),
                  ),
                ],
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: const Key('cheats'),
                    onPressed: () => ref
                        .read(routerProvider)
                        .navigate(
                          CheatsRoute(
                            romInfo: ref
                                .read(nesControllerProvider)
                                .nes!
                                .romInfo,
                          ),
                        ),
                    child: const Text('Cheats'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: toolsKey,
                    onPressed: () =>
                        ref.read(routerProvider).navigate(const ToolsRoute()),
                    child: const Text('Tools'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: resetGameKey,
                    onPressed: () {
                      ref.read(nesControllerProvider).reset();
                      ref.read(routerProvider).navigate(const EmulatorRoute());
                    },
                    child: const Text('Reset Game'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: quitGameKey,
                    onPressed: () {
                      unawaited(ref.read(nesControllerProvider).stop());
                      ref.read(routerProvider).navigate(const MainRoute());
                    },
                    child: const Text('Quit Game'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: settingsKey,
                    onPressed: () => ref
                        .read(routerProvider)
                        .navigate(const SettingsRoute()),
                    child: const Text('Settings'),
                  ),
                ),
                // Can't quit on web, and Android apps background instead of
                // quitting
                if (!kIsWeb &&
                    defaultTargetPlatform != TargetPlatform.android) ...[
                  const NesdVerticalDivider(),
                  Center(
                    child: NesdButton(
                      onPressed: () {
                        unawaited(ref.read(nesControllerProvider).stop());
                        quit();
                      },
                      child: const Text('Quit NESd'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openRewindTimeline(WidgetRef ref) async {
  ref.read(routerProvider).navigate(const EmulatorRoute());

  final nes = ref.read(nesStateProvider);
  final scrub = ref.read(rewindScrubControllerProvider.notifier);

  if (nes == null) {
    return;
  }

  nes.unpause();

  if (!nes.running) {
    try {
      await nes.events
          .firstWhere((event) => event is StatusEvent && event.running)
          .timeout(nes.requestTimeout);
    } on Object catch (error) {
      log.emulator.warning(
        'Timed out waiting to resume for rewind',
        error: error,
      );

      return;
    }
  }

  await scrub.open();
}
