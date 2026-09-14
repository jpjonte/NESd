import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/components/feature_list.dart';
import 'package:nesd_website/components/hero.dart';
import 'package:nesd_website/components/page_shell.dart';
import 'package:nesd_website/components/rom_note.dart';
import 'package:nesd_website/components/screenshot_strip.dart';
import 'package:nesd_website/release.dart';

class const LandingPage({required final ReleaseManifest release, super.key})
    extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return PageShell(
      path: '/',
      children: [
        Hero(release: release),
        const ScreenshotStrip(),
        const RomNote(),
        const FeatureList(),
      ],
    );
  }
}
