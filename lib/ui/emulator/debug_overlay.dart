import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/nesd_theme.dart';

class DebugOverlay extends HookConsumerWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(nesControllerProvider);

    final lastEvent = useState(DateTime.now());

    return StreamBuilder(
      stream: controller.frameEventStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final event = snapshot.data;

        if (event == null) {
          return const SizedBox();
        }

        final frameTime = event.frameTime.inMicroseconds / 1000.0;
        final fps = 1000 / frameTime;
        final sleepBudget = event.sleepBudget.inMicroseconds / 1000.0;
        final eventTime =
            DateTime.now().difference(lastEvent.value).inMicroseconds / 1000;
        final eps = 1000 / eventTime;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          lastEvent.value = DateTime.now();
        });

        return Align(
          alignment: Alignment.topRight,
          child: IntrinsicHeight(
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  KeyValue('Event Time', eventTime.toStringAsFixed(3)),
                  KeyValue('Frame Time', frameTime.toStringAsFixed(3)),
                  KeyValue(
                    'FPS',
                    fps.toStringAsFixed(1),
                    color: fps < 60 ? nesdRed : null,
                  ),
                  KeyValue(
                    'Events per second',
                    eps.toStringAsFixed(1),
                    color: eps < 60 ? nesdRed : null,
                  ),
                  KeyValue('Sleep Budget', sleepBudget.toStringAsFixed(3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
