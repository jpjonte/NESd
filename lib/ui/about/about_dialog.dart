import 'package:flutter/material.dart' as material show AboutDialog;
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDialog extends ConsumerWidget {
  const AboutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

    return material.AboutDialog(
      applicationVersion: packageInfo.version,
      applicationLegalese: '© 2024 John Paul Jonte',
      applicationIcon: Image.asset(
        'assets/logo.png',
        width: 128,
        height: 128,
      ),
      children: [
        InkWell(
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'GitHub',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
              ),
            ),
          ),
          onTap: () => launchUrl(Uri.parse('https://github.com/jpjonte/nesd')),
        )
      ],
    );
  }
}
