import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/general/auto_load_switch.dart';
import 'package:nesd/ui/settings/general/auto_save_interval.dart';
import 'package:nesd/ui/settings/general/auto_save_switch.dart';
import 'package:nesd/ui/settings/general/region_selector.dart';
import 'package:nesd/ui/settings/general/theme_mode_selector.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsTab(
      index: 0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            AutoSaveSwitch(),
            AutoSaveInterval(),
            AutoLoadSwitch(),
            RegionSelector(),
            ThemeModeSelector(),
          ],
        ),
      ),
    );
  }
}
