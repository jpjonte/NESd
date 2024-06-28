import 'package:flutter/material.dart';
import 'package:nes/ui/settings/general/auto_save_dropdown.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        AutoSaveDropDown(),
      ],
    );
  }
}
