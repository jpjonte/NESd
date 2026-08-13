import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';

@RoutePage()
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openTools = ref.watch(emulatorToolsControllerProvider);
    final tools = ref.read(emulatorToolsControllerProvider.notifier);

    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          'Tools',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final tool in EmulatorTool.values)
                  FocusOnHover(
                    child: SwitchSettingsTile(
                      key: Key('tool_${tool.name}'),
                      title: Text(tool.title),
                      value: openTools.contains(tool),
                      onChanged: (_) => tools.toggle(tool),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
