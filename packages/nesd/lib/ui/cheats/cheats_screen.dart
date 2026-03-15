import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/cheat/game_genie_decoder.dart';
import 'package:nesd/ui/cheats/cheat_manager.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

@RoutePage()
class CheatsScreen extends ConsumerWidget {
  const CheatsScreen({required this.romInfo, super.key});

  final RomInfo romInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheats = ref.watch(cheatManagerProvider(romInfo));
    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: const Text('Cheats'),
        actions: [
          if (cheats.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all cheats',
              onPressed: () => _confirmClearAll(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add cheat',
            onPressed: () => _showAddCheatDialog(context),
          ),
        ],
      ),
      body: cheats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cheats added',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a cheat code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: cheats.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final cheat = cheats[index];
                return _CheatListItem(
                  cheat: cheat,
                  romInfo: romInfo,
                  onEdit: () => _showEditCheatDialog(context, cheat),
                  onDelete: () => _confirmDelete(context, ref, cheat),
                );
              },
            ),
    );
  }

  void _showAddCheatDialog(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => _AddEditCheatDialog(romInfo: romInfo),
  );

  void _showEditCheatDialog(BuildContext context, Cheat cheat) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            _AddEditCheatDialog(romInfo: romInfo, cheat: cheat),
      );

  void _confirmDelete(BuildContext context, WidgetRef ref, Cheat cheat) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Cheat'),
          content: Text('Are you sure you want to delete "${cheat.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(cheatManagerProvider(romInfo).notifier)
                    .removeCheat(cheat.id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  void _confirmClearAll(BuildContext context, WidgetRef ref) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear All Cheats'),
          content: const Text('Are you sure you want to remove all cheats?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(cheatManagerProvider(romInfo).notifier)
                    .clearAllCheats();
                Navigator.of(context).pop();
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      );
}

class _CheatListItem extends ConsumerWidget {
  const _CheatListItem({
    required this.cheat,
    required this.romInfo,
    required this.onEdit,
    required this.onDelete,
  });

  final Cheat cheat;
  final RomInfo romInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressHex = cheat.address
        .toRadixString(16)
        .toUpperCase()
        .padLeft(4, '0');
    final valueHex = cheat.value
        .toRadixString(16)
        .toUpperCase()
        .padLeft(2, '0');
    final compareHex = cheat.compareValue
        ?.toRadixString(16)
        .toUpperCase()
        .padLeft(2, '0');

    return FocusOnHover(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final focused = Focus.of(context).hasFocus;

          final textColor = focused ? colorScheme.onPrimary : null;
          final subTextColor = focused
              ? colorScheme.onPrimary
              : theme.textTheme.bodySmall?.color;

          return ListTile(
            tileColor: focused ? colorScheme.primary : null,
            title: Text(cheat.name, style: TextStyle(color: textColor)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code: ${cheat.code}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextColor,
                  ),
                ),
                Text(
                  'Address: \$$addressHex',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextColor,
                  ),
                ),
                Text(
                  'Value: \$$valueHex',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextColor,
                  ),
                ),
                if (compareHex != null)
                  Text(
                    'Compare: \$$compareHex',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subTextColor,
                    ),
                  ),
              ],
            ),
            onTap: onEdit,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: cheat.enabled,
                  onChanged: (value) {
                    ref
                        .read(cheatManagerProvider(romInfo).notifier)
                        .toggleCheat(cheat.id);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: focused ? colorScheme.onPrimary : null,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddEditCheatDialog extends HookConsumerWidget {
  const _AddEditCheatDialog({required this.romInfo, this.cheat});

  final RomInfo romInfo;
  final Cheat? cheat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: cheat?.name ?? '');
    final codeController = useTextEditingController(text: cheat?.code ?? '');
    final errorText = useState<String?>(null);

    void saveCheat() {
      final name = nameController.text.trim();

      if (name.isEmpty) {
        errorText.value = 'Name is required';
        return;
      }

      final code = codeController.text.trim();
      if (code.isEmpty) {
        errorText.value = 'Code is required';
        return;
      }

      final decodedCheat = GameGenieDecoder.decode(code, name: name);

      if (decodedCheat == null) {
        errorText.value = 'Invalid Game Genie code';
        return;
      }

      final manager = ref.read(cheatManagerProvider(romInfo).notifier);

      if (cheat == null) {
        manager.addCheat(decodedCheat);
      } else {
        final updatedCheat = decodedCheat.copyWith(id: cheat!.id);
        manager.updateCheat(updatedCheat);
      }

      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: Text(cheat == null ? 'Add Cheat' : 'Edit Cheat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Infinite Lives',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Game Genie Code',
                hintText: 'e.g., SLXPLOVS',
                errorText: errorText.value,
                helperText: '6 or 8 character code',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp('[APZLGITYEOXUKSVNapzlgityeoxuksvn]'),
                ),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  );
                }),
              ],
              onChanged: (_) => errorText.value = null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: saveCheat,
          child: Text(cheat == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
