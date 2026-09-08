import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String policy;

  setUpAll(() {
    policy = File('../PRIVACY.md')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');
  });

  test('scopes the "collects nothing" promise to the app', () {
    expect(policy, contains('## What the NESd app collects'));
    expect(policy, isNot(contains('## What NESd collects')));
  });

  test('describes the website counter and its limits', () {
    expect(policy, contains('## The website (nesd.jpj.dev)'));
    expect(policy, contains('GoatCounter'));
    expect(policy, contains('It does not record your IP address'));
    expect(policy, contains('Each page is counted once per browser tab'));
    expect(policy, contains('Opening the in-browser version at /play'));
    expect(policy, contains('Self-hosted copies of the web version'));
    expect(policy, contains('If you block scripts, nothing is counted.'));
  });
}
