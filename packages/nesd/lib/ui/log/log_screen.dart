import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/log/log_actions.dart';
import 'package:nesd/ui/log/log_buffer_provider.dart';
import 'package:nesd/ui/log/log_channel_filter.dart';
import 'package:nesd/ui/log/log_export_dialog.dart';
import 'package:nesd/ui/log/log_record_tile.dart';
import 'package:nesd/ui/log/log_view_filter.dart';

@RoutePage()
class LogScreen extends HookConsumerWidget {
  const LogScreen({super.key});

  static const levelFilterKey = Key('logLevelFilter');
  static const channelFilterKey = Key('logChannelFilter');
  static const copyAllKey = Key('logCopyAll');
  static const exportKey = Key('logExport');
  static const clearKey = Key('logClear');
  static const emptyKey = Key('logEmpty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buffer = ref.watch(logBufferProvider);
    final level = useState(LogLevel.debug);
    final channels = useState(LogChannel.values.toSet());

    final records = filterLogRecords(
      buffer.records,
      level: level.value,
      channels: channels.value,
    );

    final actions = ref.watch(logActionsProvider);

    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          'Log',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
        actions: [
          IconButton(
            key: copyAllKey,
            onPressed: () => unawaited(
              actions.copyRecords(records.reversed, includeContext: true),
            ),
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all',
          ),
          IconButton(
            key: exportKey,
            onPressed: () async {
              final includeContext = await showLogExportDialog(context);

              if (includeContext == null) {
                return;
              }

              await actions.exportRecords(
                records.reversed,
                includeContext: includeContext,
              );
            },
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save to file',
          ),
          IconButton(
            key: clearKey,
            onPressed: buffer.clear,
            icon: const Icon(Icons.delete),
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: Column(
            children: [
              _FilterRow(level: level, channels: channels),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        key: emptyKey,
                        child: Text('Nothing logged yet'),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: records.length,
                        findChildIndexCallback: (key) {
                          if (key is! ObjectKey) {
                            return null;
                          }

                          final value = key.value;

                          if (value is! LogRecord) {
                            return null;
                          }

                          final index = records.indexOf(value);

                          return index == -1 ? null : index;
                        },
                        itemBuilder: (context, index) => LogRecordTile(
                          key: ObjectKey(records[index]),
                          record: records[index],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.level, required this.channels});

  final ValueNotifier<LogLevel> level;
  final ValueNotifier<Set<LogChannel>> channels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: FocusOnHover(
              child: Dropdown<LogLevel>(
                key: LogScreen.levelFilterKey,
                value: level.value,
                onChanged: (value) => level.value = value ?? LogLevel.debug,
                items: [
                  for (final value in LogLevel.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FocusOnHover(
              child: LogChannelFilter(
                key: LogScreen.channelFilterKey,
                selected: channels.value,
                onChanged: (value) => channels.value = value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
