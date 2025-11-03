import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/debugger/execution_log.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/execution_log/action_bar.dart';

class ExecutionLogWidget extends ConsumerWidget {
  const ExecutionLogWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(executionLogProvider);
    final state = ref.watch(executionLogStateProvider);

    return DefaultTextStyle(
      style: monoStyle,
      child: SizedBox(
        width: 560,
        child: Column(
          children: [
            const ActionBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: state.lines.length,
                  itemExtent: 20,
                  itemBuilder: (context, index) => ExecutionLogLineWidget(
                    line: log.printLine(state.lines[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExecutionLogLineWidget extends StatelessWidget {
  const ExecutionLogLineWidget({required this.line, super.key});

  final String line;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 20, child: Text(line));
  }
}
