import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/general/auto_save_interval.dart';
import 'package:nesd/ui/settings/general/auto_save_switch.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTab(
      index: 0,
      child: ListView(
        children: const [
          AutoSaveSwitch(),
          AutoSaveInterval(),
        ],
      ),
    );
  }
}
