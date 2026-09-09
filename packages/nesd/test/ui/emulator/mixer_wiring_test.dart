import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';

import '../mocks.dart';
import '../robot.dart';

void main() {
  testWidgets('the mixer settings reach the worker at ROM load and on later '
      'changes', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    final settings = r.container.read(settingsControllerProvider.notifier)
      ..mixer = const MixerSettings(sunsoft5b: 0.5);

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

    List<SetMixerCommand> sent() => r.isolateHandles.single.sentCommands
        .whereType<SetMixerCommand>()
        .toList();

    expect(sent().last.mixer.sunsoft5b, 0.5);

    settings.mixer = const MixerSettings(sunsoft5b: 0);

    await r.fixAsync();

    expect(sent().last.mixer.sunsoft5b, 0);

    await tester.runAsync(controller.stop);
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
