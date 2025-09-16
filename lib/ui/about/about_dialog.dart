import 'package:flutter/material.dart' as material show AboutDialog;
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/theme/base.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDialog extends ConsumerWidget {
  const AboutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(textTheme: _updateTextTheme(theme)),
      child: material.AboutDialog(
        applicationVersion: packageInfo.version,
        applicationLegalese: '© 2024 - 2025 John Paul Jonte',
        applicationIcon: Image.asset(
          'assets/logo.png',
          width: 128,
          height: 128,
        ),
        children: [
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'GitHub',
                style: baseTextStyle.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
              ),
            ),
            onTap:
                () => launchUrl(Uri.parse('https://github.com/jpjonte/nesd')),
          ),
        ],
      ),
    );
  }

  TextTheme _updateTextTheme(ThemeData theme) {
    final textTheme = theme.textTheme;

    final color = theme.colorScheme.onPrimary;

    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(color: color),
      displayMedium: textTheme.displayMedium?.copyWith(color: color),
      displaySmall: textTheme.displaySmall?.copyWith(color: color),
      headlineLarge: textTheme.headlineLarge?.copyWith(color: color),
      headlineMedium: textTheme.headlineMedium?.copyWith(color: color),
      headlineSmall: textTheme.headlineSmall?.copyWith(color: color),
      titleLarge: textTheme.titleLarge?.copyWith(color: color),
      titleMedium: textTheme.titleMedium?.copyWith(color: color),
      titleSmall: textTheme.titleSmall?.copyWith(color: color),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: color),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: color),
      bodySmall: textTheme.bodySmall?.copyWith(color: color),
      labelLarge: textTheme.labelLarge?.copyWith(color: color),
      labelMedium: textTheme.labelMedium?.copyWith(color: color),
      labelSmall: textTheme.labelSmall?.copyWith(color: color),
    );
  }
}
