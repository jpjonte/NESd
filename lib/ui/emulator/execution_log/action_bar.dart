import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/debugger/execution_log.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/ui/theme/base.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: nesdRed[900],
      child: const Row(
        children: [RecordButton(), WriteToFileButton(), ClearButton()],
      ),
    );
  }
}

class RecordButton extends ConsumerWidget {
  const RecordButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionLogNotifierProvider);
    final log = ref.read(executionLogProvider);

    return IconButton(
      onPressed: log.toggle,
      icon: Icon(state.enabled ? Icons.stop_circle : MdiIcons.recordCircle),
      color: state.enabled ? nesdRed : Colors.white,
      tooltip: state.enabled ? 'Stop Recording' : 'Start Recording',
    );
  }
}

class WriteToFileButton extends ConsumerWidget {
  const WriteToFileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(executionLogProvider);

    return IconButton(
      onPressed: () async {
        final file = await FilePicker.platform.saveFile(
          type: FileType.custom,
          allowedExtensions: ['log', 'txt'],
        );

        if (file != null) {
          log.dumpToFile(file);
        }
      },
      icon: const Icon(MdiIcons.fileDownload),
      color: Colors.white,
      tooltip: 'Write log to File',
    );
  }
}

class ClearButton extends ConsumerWidget {
  const ClearButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.read(executionLogProvider);

    return IconButton(
      onPressed: log.clear,
      icon: const Icon(Icons.delete),
      color: Colors.white,
      tooltip: 'Clear log',
    );
  }
}
