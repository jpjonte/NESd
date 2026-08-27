import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

void main() {
  ui.ImageFilter identityFilter(ui.FragmentShader shader) =>
      ui.ImageFilter.matrix(Matrix4.identity().storage);

  Future<ui.FragmentShader> loadShader(WidgetTester tester) async {
    late ui.FragmentShader shader;

    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset('shaders/crt.frag');

      shader = program.fragmentShader();
    });

    return shader;
  }

  testWidgets('an active filter with a ready shader wraps the texture in '
      'an image filter built from the shader', (tester) async {
    final shader = await loadShader(tester);

    ui.FragmentShader? filteredShader;

    await tester.pumpWidget(
      frameTextureLayer(
        textureId: 1,
        imageWidth: 256,
        imageHeight: 240,
        filter: VideoFilter.crt,
        shader: shader,
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: (shader) {
          filteredShader = shader;

          return identityFilter(shader);
        },
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ImageFiltered),
        matching: find.byType(Texture),
      ),
      findsOneWidget,
    );
    expect(filteredShader, same(shader));
  });

  testWidgets('changing filter parameters re-keys the filter widget so the '
      'layer re-snapshots the uniforms', (tester) async {
    final shader = await loadShader(tester);

    Widget layer(CrtFilterSettings crtFilter) => frameTextureLayer(
      textureId: 1,
      imageWidth: 256,
      imageHeight: 240,
      filter: VideoFilter.crt,
      shader: shader,
      crtFilter: crtFilter,
      shaderFilterSupported: true,
      imageFilterFactory: identityFilter,
    );

    final initial = layer(const CrtFilterSettings());
    final changed = layer(const CrtFilterSettings(curvature: 0.1));
    final unchanged = layer(const CrtFilterSettings());

    expect(initial, isA<ImageFiltered>());
    expect(initial.key, isNotNull);
    expect(initial.key, isNot(changed.key));
    expect(initial.key, unchanged.key);
  });

  testWidgets('the texture stays unfiltered when shader image filters are '
      'unsupported', (tester) async {
    final shader = await loadShader(tester);

    await tester.pumpWidget(
      frameTextureLayer(
        textureId: 1,
        imageWidth: 256,
        imageHeight: 240,
        filter: VideoFilter.crt,
        shader: shader,
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: false,
        imageFilterFactory: identityFilter,
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('a pending shader leaves the texture unfiltered', (tester) async {
    await tester.pumpWidget(
      frameTextureLayer(
        textureId: 1,
        imageWidth: 256,
        imageHeight: 240,
        filter: VideoFilter.crt,
        shader: null,
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: identityFilter,
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('filter none leaves the texture unfiltered', (tester) async {
    await tester.pumpWidget(
      frameTextureLayer(
        textureId: 1,
        imageWidth: 256,
        imageHeight: 240,
        filter: VideoFilter.none,
        shader: null,
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: identityFilter,
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Texture), findsOneWidget);
  });
}
