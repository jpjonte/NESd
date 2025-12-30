import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/ui/cheats/cheat_manager.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

@RoutePage()
class CheatsScreen extends ConsumerStatefulWidget {
  const CheatsScreen({required this.romInfo, super.key});

  final RomInfo romInfo;

  @override
  ConsumerState<CheatsScreen> createState() => _CheatsScreenState();
}

class _CheatsScreenState extends ConsumerState<CheatsScreen> {
  @override
  void initState() {
    super.initState();

    // Load cheats for this ROM
    Future.microtask(
      () => ref.read(cheatManagerProvider.notifier).loadCheats(widget.romInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheats = ref.watch(cheatManagerProvider);
    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: const Text('Cheats'),
        actions: [
          if (cheats.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all cheats',
              onPressed: () => _confirmClearAll(),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add cheat',
            onPressed: () => _showAddCheatDialog(),
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
          : ListView.builder(
              itemCount: cheats.length,
              itemBuilder: (context, index) {
                final cheat = cheats[index];
                return _CheatListItem(
                  cheat: cheat,
                  romInfo: widget.romInfo,
                  onEdit: () => _showEditCheatDialog(cheat),
                  onDelete: () => _confirmDelete(cheat),
                );
              },
            ),
    );
  }

  void _showAddCheatDialog() => showDialog<void>(
    context: context,
    builder: (context) => _AddEditCheatDialog(romInfo: widget.romInfo),
  );

  void _showEditCheatDialog(Cheat cheat) => showDialog<void>(
    context: context,
    builder: (context) =>
        _AddEditCheatDialog(romInfo: widget.romInfo, cheat: cheat),
  );

  void _confirmDelete(Cheat cheat) => showDialog<void>(
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
                .read(cheatManagerProvider.notifier)
                .removeCheat(cheat.id, widget.romInfo);
            Navigator.of(context).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  void _confirmClearAll() => showDialog<void>(
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
                .read(cheatManagerProvider.notifier)
                .clearAllCheats(widget.romInfo);
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
    final theme = Theme.of(context);
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(cheat.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: \$$addressHex', style: theme.textTheme.bodySmall),
            Text('Value: \$$valueHex', style: theme.textTheme.bodySmall),
            if (compareHex != null)
              Text('Compare: \$$compareHex', style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: cheat.enabled,
              onChanged: (value) {
                ref
                    .read(cheatManagerProvider.notifier)
                    .toggleCheat(cheat.id, romInfo);
              },
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _AddEditCheatDialog extends ConsumerStatefulWidget {
  const _AddEditCheatDialog({required this.romInfo, this.cheat});

  final RomInfo romInfo;
  final Cheat? cheat;

  @override
  ConsumerState<_AddEditCheatDialog> createState() =>
      _AddEditCheatDialogState();
}

class _AddEditCheatDialogState extends ConsumerState<_AddEditCheatDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    final cheat = widget.cheat;

    _nameController = TextEditingController(text: cheat?.name ?? '');
    _codeController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.cheat == null ? 'Add Cheat' : 'Edit Cheat'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Infinite Lives',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Game Genie Code',
              hintText: 'e.g., SLXPLOVS',
              errorText: _errorText,
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
            onChanged: (_) => setState(() => _errorText = null),
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
        onPressed: _saveCheat,
        child: Text(widget.cheat == null ? 'Add' : 'Save'),
      ),
    ],
  );

  void _saveCheat() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = 'Name is required');
      return;
    }

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = 'Code is required');
      return;
    }

    final cheat = ref
        .read(cheatManagerProvider.notifier)
        .decodeGameGenie(code, name: name);

    if (cheat == null) {
      setState(() => _errorText = 'Invalid Game Genie code');
      return;
    }

    if (widget.cheat == null) {
      ref.read(cheatManagerProvider.notifier).addCheat(cheat, widget.romInfo);
    } else {
      final updatedCheat = cheat.copyWith(id: widget.cheat!.id);
      ref
          .read(cheatManagerProvider.notifier)
          .updateCheat(updatedCheat, widget.romInfo);
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();

    super.dispose();
  }
}
