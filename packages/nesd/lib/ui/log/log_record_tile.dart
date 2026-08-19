import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';
import 'package:nesd/ui/common/context_menu.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/log/log_actions.dart';
import 'package:nesd/ui/theme/base.dart';

const _chevronSlot = 18.0;

const _copiedFeedback = Duration(seconds: 1);

class LogRecordTile extends HookConsumerWidget {
  const LogRecordTile({required this.record, super.key});

  final LogRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = useState(false);
    final actions = ref.watch(logActionsProvider);

    final color = switch (record.level) {
      LogLevel.debug => Colors.white54,
      LogLevel.info => Colors.white,
      LogLevel.warning => Colors.orange,
      LogLevel.error => nesdRed[300],
    };

    return ContextMenu(
      contextMenuBuilder: (context, close) => [
        ListTile(
          title: const Text('Copy'),
          onTap: () {
            unawaited(actions.copyRecord(record));

            close();
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: record.hasDetails
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: GestureDetector(
                      onTap: record.hasDetails
                          ? () => expanded.value = !expanded.value
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: _chevronSlot,
                            child: record.hasDetails
                                ? Icon(
                                    expanded.value
                                        ? Icons.expand_more
                                        : Icons.chevron_right,
                                    size: 16,
                                    color: color,
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              formatRecordForViewer(record),
                              style: monoStyle.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _CopyButton(record: record, actions: actions),
              ],
            ),
            if (expanded.value) _Details(record: record),
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends HookWidget {
  const _CopyButton({required this.record, required this.actions});

  final LogRecord record;
  final LogActions actions;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final copied = useState(false);
    final timer = useRef<Timer?>(null);

    useEffect(
      () =>
          () => timer.value?.cancel(),
      const [],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTap: () {
          unawaited(actions.copyRecord(record));

          copied.value = true;

          timer.value?.cancel();
          timer.value = Timer(_copiedFeedback, () => copied.value = false);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 1),
          child: Icon(
            copied.value ? Icons.check : Icons.content_copy,
            size: 14,
            color: copied.value
                ? Colors.greenAccent
                : (hovered.value ? Colors.white70 : Colors.white24),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: SelectableText(
        formatRecordDetails(record),
        style: monoStyle.copyWith(color: Colors.white70),
      ),
    );
  }
}
