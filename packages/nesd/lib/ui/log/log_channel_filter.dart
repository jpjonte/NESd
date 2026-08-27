import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/log/log_colors.dart';

class LogChannelFilter extends HookWidget {
  const LogChannelFilter({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  static const allKey = Key('logChannelAll');

  static Key checkboxKey(LogChannel channel) =>
      Key('logChannelCheckbox_${channel.name}');

  static Key onlyKey(LogChannel channel) =>
      Key('logChannelOnly_${channel.name}');

  static Key dotKey(LogChannel channel) => Key('logChannelDot_${channel.name}');

  final Set<LogChannel> selected;
  final ValueChanged<Set<LogChannel>> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(MenuController.new);

    final theme = Theme.of(context);
    final focused = Focus.of(context).hasFocus;

    final color = focused
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final border = theme.inputDecorationTheme.border!.borderSide;

    return MenuAnchor(
      controller: controller,
      menuChildren: [
        MenuItemButton(
          key: allKey,
          onPressed: () => onChanged(LogChannel.values.toSet()),
          child: const Text('All channels'),
        ),
        const Divider(height: 1),
        for (final channel in LogChannel.values)
          _ChannelRow(
            channel: channel,
            checked: selected.contains(channel),
            onToggle: () => onChanged(_toggled(channel)),
            onOnly: () {
              onChanged({channel});

              controller.close();
            },
          ),
      ],
      builder: (context, _, _) => InkWell(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderSide: border.copyWith(color: color),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label,
                    overflow: TextOverflow.ellipsis,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: color,
                      fontVariations: const [FontVariation.weight(700)],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Set<LogChannel> _toggled(LogChannel channel) {
    final next = {...selected};

    if (!next.remove(channel)) {
      next.add(channel);
    }

    return next;
  }

  String get _label => switch (selected.length) {
    0 => 'No channels',
    1 => selected.first.title,
    final length when length == LogChannel.values.length => 'All channels',
    final length => '$length channels',
  };
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.checked,
    required this.onToggle,
    required this.onOnly,
  });

  final LogChannel channel;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            key: LogChannelFilter.checkboxKey(channel),
            value: checked,
            onChanged: (_) => onToggle(),
          ),
          Container(
            key: LogChannelFilter.dotKey(channel),
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: logChannelColor(channel),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 110, child: Text(channel.title)),
          TextButton(
            key: LogChannelFilter.onlyKey(channel),
            onPressed: onOnly,
            child: const Text('Only'),
          ),
        ],
      ),
    );
  }
}
