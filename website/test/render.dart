import 'dart:convert';

import 'package:jaspr/server.dart';

Future<String> renderHtml(
  Component component, {
  String path = '/',
  bool fullDocument = false,
}) async {
  if (!Jaspr.isInitialized) {
    Jaspr.initializeApp();
  }

  final response = await renderComponent(
    component,
    request: Request('GET', Uri.parse('https://nesd.jpj.dev$path')),
    standalone: !fullDocument,
  );

  return utf8.decode(response.body);
}
