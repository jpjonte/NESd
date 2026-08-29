import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';

import '../mocks.dart';
import '../robot.dart';

void main() {
  testWidgets('the turbo speed setting reaches the worker at ROM load and '
      'on later changes', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    final settings = r.container.read(settingsControllerProvider.notifier)
      ..turboSpeed = TurboSpeed.x3;

    final controller = r.container.read(nesControllerProvider);

    final loaded = await tester.runAsync(
      () => controller.loadRom(
        const FilesystemFile(
          path: '/not/on/any/filesystem.nes',
          name: 'direct.nes',
          type: FilesystemFileType.file,
        ),
        data: minimalValidRom(),
      ),
    );

    await r.fixAsync();

    expect(loaded, isTrue);

    List<SetTurboSpeedCommand> sent() => r.isolateHandles.single.sentCommands
        .whereType<SetTurboSpeedCommand>()
        .toList();

    expect(sent().last.speed, TurboSpeed.x3);

    settings.turboSpeed = TurboSpeed.x2;

    await r.fixAsync();

    expect(sent().last.speed, TurboSpeed.x2);

    await tester.runAsync(controller.stop);
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
