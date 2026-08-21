import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:nesd_website/app.dart';
import 'package:nesd_website/content.dart';
import 'package:nesd_website/main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  final inputs = SiteInputs.fromEnvironment(
    Platform.environment,
    workingDirectory: Directory.current.path,
  );

  runApp(App(content: SiteContent.load(inputs)));
}
