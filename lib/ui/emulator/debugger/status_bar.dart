import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/theme/base.dart';

final registerHeaderStyle = monoStyle.copyWith(color: Colors.grey[400]);

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debuggerNotifierProvider);
    final debugger = ref.watch(debuggerProvider);

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: nesdRed[800],
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatusBarItem('PC', Text(state.PC.toHex(width: 4))),
                  StatusBarItem('A', Text(state.A.toHex())),
                  StatusBarItem('X', Text(state.X.toHex())),
                  StatusBarItem('Y', Text(state.Y.toHex())),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => debugger.showStack(),
                    onExit: (_) => debugger.hideStack(),
                    child: StatusBarItem('SP', Text(state.SP.toHex())),
                  ),
                  StatusBarItem('C', BoolIcon(value: state.C)),
                  StatusBarItem('Z', BoolIcon(value: state.Z)),
                  StatusBarItem('I', BoolIcon(value: state.I)),
                  StatusBarItem('D', BoolIcon(value: state.D)),
                  StatusBarItem('B', BoolIcon(value: state.B)),
                  StatusBarItem('V', BoolIcon(value: state.V)),
                  StatusBarItem('N', BoolIcon(value: state.N)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('IRQs', style: registerHeaderStyle),
                  StatusBarItem(
                    'Mapper',
                    BoolIcon(value: state.irq & IrqSource.mapper.value > 0),
                  ),
                  StatusBarItem(
                    'DMC',
                    BoolIcon(value: state.irq & IrqSource.apuDmc.value > 0),
                  ),
                  StatusBarItem(
                    'Frame Counter',
                    BoolIcon(
                      value: state.irq & IrqSource.apuFrameCounter.value > 0,
                    ),
                  ),
                  StatusBarItem('NMI', BoolIcon(value: state.nmi)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatusBarItem('Scanline', Text('${state.scanline}')),
                  StatusBarItem('Cycle', Text('${state.cycle}')),
                  StatusBarItem('v', Text(state.v.toHex(width: 4))),
                  StatusBarItem('t', Text(state.t.toHex(width: 4))),
                  StatusBarItem('x', Text(state.x.toHex())),
                  StatusBarItem(
                    'Sprite Overflow',
                    BoolIcon(value: state.spriteOverflow),
                  ),
                  StatusBarItem(
                    'Sprite 0 Hit',
                    BoolIcon(value: state.sprite0Hit),
                  ),
                  StatusBarItem('VBlank', BoolIcon(value: state.vBlank)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBarItem extends StatelessWidget {
  const StatusBarItem(this.label, this.value, {super.key});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [Text(label, style: registerHeaderStyle), value],
    );
  }
}

class BoolIcon extends StatelessWidget {
  const BoolIcon({required this.value, super.key});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Icon(value ? Icons.check : Icons.close, size: 14);
  }
}
