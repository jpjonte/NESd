import 'package:flutter/material.dart' hide AboutDialog;
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      child: ButtonSettingsTile(
        title: const Text('About NESd'),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AboutDialog(),
        ),
      ),
    );
  }
}
