import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/emulator/debugger/address_dialog.dart';
import 'package:nesd/ui/emulator/debugger/breakpoint_dialog.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/nesd_theme.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: nesdRed[900],
      child: Row(
        children: [
          const ResumeButton(),
          const PauseButton(),
          const StepIntoButton(),
          const StepOverButton(),
          const StepOutButton(),
          const RunToAddressButton(),
          GoToPcButton(scrollController: scrollController),
          GoToAddressButton(scrollController: scrollController),
          BreakpointListButton(scrollController: scrollController),
          const OpenExecutionLogButton(),
        ],
      ),
    );
  }
}

class ResumeButton extends ConsumerWidget {
  const ResumeButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.read(nesControllerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: state.enabled ? nesController.unpause : null,
      icon: const Icon(Icons.play_arrow),
      tooltip: 'Resume',
    );
  }
}

class PauseButton extends ConsumerWidget {
  const PauseButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.read(nesControllerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: !state.enabled ? nesController.pause : null,
      icon: const Icon(Icons.pause),
      tooltip: 'Pause',
    );
  }
}

class StepIntoButton extends ConsumerWidget {
  const StepIntoButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.read(nesControllerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: state.enabled ? nesController.stepInto : null,
      icon: const Icon(MdiIcons.debugStepInto),
      tooltip: 'Step Into',
    );
  }
}

class StepOverButton extends ConsumerWidget {
  const StepOverButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.read(nesControllerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: state.enabled ? nesController.stepOver : null,
      icon: const Icon(MdiIcons.debugStepOver),
      tooltip: 'Step Over',
    );
  }
}

class StepOutButton extends ConsumerWidget {
  const StepOutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.read(nesControllerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed:
          state.enabled && state.canStepOut ? nesController.stepOut : null,
      icon: const Icon(MdiIcons.debugStepOut),
      tooltip: 'Step Out',
    );
  }
}

class RunToAddressButton extends ConsumerWidget {
  const RunToAddressButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);
    final nesController = ref.read(nesControllerProvider);

    return IconButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AddressDialog(
          title: 'Run to address',
          onSubmitted: (address) {
            debugger.addBreakpoint(
              Breakpoint(address, hidden: true, removeOnHit: true),
            );

            nesController.unpause();
          },
        ),
      ),
      icon: const Icon(Icons.vertical_align_bottom),
      tooltip: 'Run to address',
    );
  }
}

class GoToPcButton extends ConsumerWidget {
  const GoToPcButton({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: state.enabled
          ? () {
              final pcOffset = calculateAddressScrollOffset(state, state.PC);

              jumpTo(scrollController, pcOffset);
            }
          : null,
      icon: const Icon(Icons.gps_fixed),
      tooltip: 'Go to program counter',
    );
  }
}

class GoToAddressButton extends ConsumerWidget {
  const GoToAddressButton({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debuggerNotifierProvider);

    return IconButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AddressDialog(
          title: 'Go to address',
          onSubmitted: (address) {
            final offset = calculateAddressScrollOffset(state, address);

            jumpTo(scrollController, offset);
          },
        ),
      ),
      icon: const Icon(Icons.subdirectory_arrow_right),
      tooltip: 'Go to address',
    );
  }
}

class BreakpointListButton extends StatelessWidget {
  const BreakpointListButton({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => BreakpointDialog(
            scrollController: scrollController,
          ),
        );
      },
      icon: const Icon(Icons.circle),
      tooltip: 'Breakpoints',
    );
  }
}

class OpenExecutionLogButton extends ConsumerWidget {
  const OpenExecutionLogButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(debuggerNotifierProvider.notifier);

    return IconButton(
      onPressed: () => notifier.toggleExecutionLog(),
      icon: const Icon(Icons.list),
      tooltip: 'Execution log',
    );
  }
}
