import 'package:jaspr/jaspr.dart';
import 'package:nesd_website/components/feature_list.dart';
import 'package:nesd_website/components/hero.dart';
import 'package:nesd_website/components/page_shell.dart';
import 'package:nesd_website/components/screenshot_strip.dart';
import 'package:nesd_website/release.dart';

class LandingPage extends StatelessComponent {
  const LandingPage({required this.release, super.key});

  final ReleaseManifest release;

  @override
  Component build(BuildContext context) {
    return PageShell(
      children: [
        Hero(release: release),
        const ScreenshotStrip(),
        const FeatureList(),
      ],
    );
  }
}
