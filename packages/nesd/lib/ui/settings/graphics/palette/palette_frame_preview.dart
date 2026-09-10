import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
import 'package:nesd/ui/settings/settings.dart';

typedef RepaintFrame =
    Future<RepaintFrameResponse?> Function(Uint32List palette);

final paletteRepaintProvider = Provider<RepaintFrame?>((ref) {
  final nes = ref.watch(nesStateProvider);

  return nes?.requestRepaintFrame;
});

class PaletteFrameRenderer extends ChangeNotifier {
  ui.Image? get image => _image;

  ui.Image? _image;

  (RepaintFrame, Uint32List)? _pending;
  bool _rendering = false;
  bool _disposed = false;

  void request(RepaintFrame repaint, Uint32List palette) {
    _pending = (repaint, palette);

    if (_rendering) {
      return;
    }

    unawaited(_drain());
  }

  Future<void> _drain() async {
    _rendering = true;

    try {
      while (_pending != null && !_disposed) {
        final (repaint, palette) = _pending!;

        _pending = null;

        final response = await repaint(palette);
        final pixels = response?.pixels;

        if (_disposed) {
          return;
        }

        if (response == null || pixels == null) {
          continue;
        }

        final rendered = await _decode(
          pixels.materialize().asUint8List(),
          response.width,
          response.height,
        );

        if (_disposed) {
          rendered.dispose();

          return;
        }

        _replaceImage(rendered);
      }
    } finally {
      _rendering = false;
    }
  }

  Future<ui.Image> _decode(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  void _replaceImage(ui.Image rendered) {
    final outgoing = _image;

    _image = rendered;

    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) => outgoing?.dispose());
  }

  @override
  void dispose() {
    _disposed = true;

    _image?.dispose();
    _image = null;

    super.dispose();
  }
}

class PaletteFramePreview extends HookConsumerWidget {
  const PaletteFramePreview({super.key});

  static const imageKey = Key('paletteFramePreviewImage');

  static const previewKey = Key('paletteFramePreview');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaint = ref.watch(paletteRepaintProvider);
    final palette = ref.watch(nesPaletteProvider);
    final settings = ref.watch(settingsControllerProvider);
    final shaderState = ref.watch(videoFilterRegistryProvider);

    final renderer = useMemoized(PaletteFrameRenderer.new);

    useEffect(() => renderer.dispose, [renderer]);
    useListenable(renderer);

    useEffect(() {
      if (repaint != null) {
        renderer.request(repaint, palette);
      }

      return null;
    }, [renderer, repaint, palette]);

    final image = renderer.image;

    if (image == null) {
      return const SizedBox.shrink();
    }

    final overscan = settings.overscan;

    final visibleWidth = overscan.visibleWidth(image.width);
    final visibleHeight = overscan.visibleHeight(image.height);

    return LayoutBuilder(
      builder: (_, constraints) {
        final pixelAspectRatio = calculatePixelAspectRatio(
          pixelAspectRatio: settings.pixelAspectRatio,
          customPixelAspectRatio: settings.customPixelAspectRatio,
          region: settings.region ?? Region.ntsc,
          constraints: constraints,
        );

        return AspectRatio(
          key: previewKey,
          aspectRatio: visibleWidth / visibleHeight * pixelAspectRatio,
          child: frameFilterLayer(
            imageWidth: image.width,
            imageHeight: image.height,
            filters: settings.videoFilters,
            shaders: shaderState.shaders,
            crtFilter: settings.crtFilter,
            shaderFilterSupported: ui.ImageFilter.isShaderFilterSupported,
            imageFilterFactory: ui.ImageFilter.shader,
            overscan: overscan,
            child: RawImage(
              key: imageKey,
              image: image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      },
    );
  }
}
