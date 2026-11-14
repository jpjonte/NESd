import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/backup/settings_backup.dart';
import 'package:nesd/ui/settings/backup/settings_backup_actions.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

class ExportSettingsButton extends ConsumerWidget {
  const ExportSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusOnHover(
    child: ButtonSettingsTile(
      title: const Text('Export settings…'),
      onPressed: () => _export(ref),
    ),
  );

  Future<void> _export(WidgetRef ref) async {
    final settings = ref.read(settingsControllerProvider);
    final actions = ref.read(settingsBackupActionsProvider);
    final toaster = ref.read(toasterProvider);
    final now = DateTime.now();

    try {
      final uri = await actions.exportBackup(
        encodeSettingsBackup(settings, now: now),
        fileName: settingsBackupFileName(now),
      );

      if (uri == null) {
        return;
      }
    } on Object catch (e, s) {
      log.settings.error('Failed to export settings', error: e, stackTrace: s);

      toaster.send(Toast.error('Could not export settings'));

      return;
    }

    toaster.send(Toast.info('Settings exported'));
  }
}

class ImportSettingsButton extends ConsumerWidget {
  const ImportSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusOnHover(
    child: ButtonSettingsTile(
      title: const Text('Import settings…'),
      onPressed: () => _import(context, ref),
    ),
  );

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(settingsBackupActionsProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final toaster = ref.read(toasterProvider);

    final file = await actions.pickBackup();

    if (file == null) {
      return;
    }

    final Map<String, dynamic> backup;

    try {
      backup = decodeSettingsBackup(
        utf8.decode(await file.readAsBytes(), allowMalformed: true),
      );
    } on FormatException catch (e) {
      toaster.send(Toast.error('Could not import ${file.name}: ${e.message}'));

      return;
    } on Object catch (e, s) {
      log.settings.error(
        'Failed to read settings backup ${file.name}',
        error: e,
        stackTrace: s,
      );

      toaster.send(Toast.error('Could not import ${file.name}'));

      return;
    }

    if (!context.mounted) {
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: const Text('Import settings?'),
      content: Text(
        'Replace your current settings with the ones in ${file.name}? '
        'Recent and favorite ROMs are kept.',
      ),
      confirmLabel: const Text('Import'),
    );

    if (confirmed != true) {
      return;
    }

    final skipped = controller.importBackup(backup);

    if (skipped == 0) {
      toaster.send(Toast.info('Settings imported'));

      return;
    }

    toaster.send(
      Toast.warning(
        skipped == 1
            ? 'Settings imported; 1 entry could not be read and was skipped'
            : 'Settings imported; $skipped entries could not be read and '
                  'were skipped',
      ),
    );
  }
}

class ResetSettingsButton extends HookConsumerWidget {
  const ResetSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = useState(false);

    return FocusOnHover(
      onFocusChange: (value) => focused.value = value,
      child: IconButtonSettingsTile(
        title: const Text('Reset to defaults'),
        onPressed: () => _reset(context, ref),
        icon: Icons.restart_alt,
        color: focused.value ? Theme.of(context).colorScheme.onPrimary : null,
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(settingsControllerProvider.notifier);
    final toaster = ref.read(toasterProvider);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: const Text('Reset settings?'),
      content: const Text(
        'Reset all settings, bindings, cheats and breakpoints to their '
        'defaults? Recent and favorite ROMs are kept.',
      ),
      confirmLabel: const Text('Reset'),
    );

    if (confirmed != true) {
      return;
    }

    controller.resetToDefaults();

    toaster.send(Toast.info('Settings reset to defaults'));
  }
}
