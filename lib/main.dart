import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes/cartridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NES',
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12.0),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: AppWidget(),
      ),
    );
  }
}

class AppWidget extends HookWidget {
  const AppWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cartridgeState = useState<Cartridge?>(null);
    final errorState = useState<String?>(null);

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'NES',
          menus: [
            PlatformMenuItem(
              label: 'About',
              onSelected: () {},
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'Open...',
              shortcut: const CharacterActivator('o', meta: true),
              onSelected: () async {
                await _loadRom(cartridgeState, errorState);
              },
            ),
          ],
        ),
      ],
      child: Row(
        children: [
          const Expanded(child: DisplayWidget()),
          if (cartridgeState.value case final cartridge?)
            CartridgeInfoWidget(cartridge: cartridge),
          if (errorState.value != null)
            Text(
              errorState.value!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadRom(
    ValueNotifier<Cartridge?> cartridgeState,
    ValueNotifier<String?> error,
  ) async {
    error.value = null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['nes'],
    );

    if (result == null) {
      return;
    }

    cartridgeState.value = null;

    final path = result.files.single.path;

    if (path == null) {
      return;
    }

    try {
      cartridgeState.value = Cartridge.fromFile(path);
    } on Exception catch (e) {
      error.value = 'Failed to load ROM: $e';
    }
  }
}

class CartridgeInfoWidget extends StatelessWidget {
  const CartridgeInfoWidget({
    required this.cartridge,
    super.key,
  });

  final Cartridge cartridge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableRow('Filename', File(cartridge.file).uri.pathSegments.last),
            TableRow('ROM format', cartridge.romFormat.toString()),
            TableRow('PRG ROM size', '${cartridge.prgRomSize} bytes'),
            TableRow('CHR ROM size', '${cartridge.chrRomSize} bytes'),
            TableRow('Nametable layout', '${cartridge.nametableLayout}'),
            TableRow(
              'Alternative nametable layout',
              '${cartridge.alternativeNametableLayout}',
            ),
            TableRow('Has battery', '${cartridge.hasBattery}'),
            TableRow('Has trainer', '${cartridge.hasTrainer}'),
            TableRow('Console type', '${cartridge.consoleType}'),
            TableRow('Mapper', cartridge.mapper.name),
            TableRow('PRG RAM size', '${cartridge.prgRamSize} bytes'),
            TableRow('TV system', '${cartridge.tvSystem}'),
          ],
        ),
      ),
    );
  }
}

class TableRow extends StatelessWidget {
  const TableRow(
    this.label,
    this.value, {
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// NES resolution: 256x224 (NTSC) or 256x240 (PAL)

class DisplayWidget extends StatelessWidget {
  const DisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadImage(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final image = snapshot.data;

        if (image == null) {
          return const Center(child: Text('Failed to load image'));
        }

        return CustomPaint(
          painter: EmulatorPainter(image: image),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Future<ui.Image> _loadImage() async {
    final pixels = List.filled(256 * 224, 0xFF000000);

    void setPixel(int x, int y, int color) {
      final index = x + y * 256;
      pixels[index] = color;
    }

    setPixel(0, 0, 0xFFFFFFFF);
    setPixel(1, 0, 0xFFFFFFFF);
    setPixel(2, 0, 0xFFFFFFFF);
    setPixel(1, 1, 0xFFFFFFFF);
    setPixel(1, 2, 0xFFFFFFFF);
    setPixel(1, 3, 0xFFFFFFFF);
    setPixel(1, 4, 0xFFFFFFFF);

    setPixel(4, 0, 0xFFFFFFFF);
    setPixel(5, 0, 0xFFFFFFFF);
    setPixel(6, 0, 0xFFFFFFFF);
    setPixel(4, 1, 0xFFFFFFFF);
    setPixel(4, 2, 0xFFFFFFFF);
    setPixel(5, 2, 0xFFFFFFFF);
    setPixel(6, 2, 0xFFFFFFFF);
    setPixel(4, 3, 0xFFFFFFFF);
    setPixel(4, 4, 0xFFFFFFFF);
    setPixel(5, 4, 0xFFFFFFFF);
    setPixel(6, 4, 0xFFFFFFFF);

    setPixel(8, 0, 0xFFFFFFFF);
    setPixel(9, 0, 0xFFFFFFFF);
    setPixel(10, 0, 0xFFFFFFFF);
    setPixel(8, 1, 0xFFFFFFFF);
    setPixel(8, 2, 0xFFFFFFFF);
    setPixel(9, 2, 0xFFFFFFFF);
    setPixel(10, 2, 0xFFFFFFFF);
    setPixel(10, 3, 0xFFFFFFFF);
    setPixel(8, 4, 0xFFFFFFFF);
    setPixel(9, 4, 0xFFFFFFFF);
    setPixel(10, 4, 0xFFFFFFFF);

    setPixel(12, 0, 0xFFFFFFFF);
    setPixel(13, 0, 0xFFFFFFFF);
    setPixel(14, 0, 0xFFFFFFFF);
    setPixel(13, 1, 0xFFFFFFFF);
    setPixel(13, 2, 0xFFFFFFFF);
    setPixel(13, 3, 0xFFFFFFFF);
    setPixel(13, 4, 0xFFFFFFFF);

    final pixelData = Uint8List.fromList(
      pixels
          .expand(
            (value) => [
              (value >> 16) & 0xFF,
              (value >> 8) & 0xFF,
              value & 0xFF,
              (value >> 24) & 0xFF,
            ],
          )
          .toList(),
    );

    final buffer = await ui.ImmutableBuffer.fromUint8List(pixelData);

    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: 256,
      height: 224,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();

    final frame = await codec.getNextFrame();

    return frame.image;
  }
}

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({required this.image});

  final ui.Image image;

  final Paint backgroundPaint = Paint()..color = Colors.black;

  final Paint borderPaint = Paint()
    ..strokeWidth = 1
    ..color = Colors.white
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final center = Offset(size.width / 2, size.height / 2);

    final scale = max(1, min(size.width ~/ 256, size.height ~/ 224));

    final topLeft = center - const Offset(128, 112) * scale.toDouble();

    final matrix = Matrix4.identity().scaled(scale.toDouble())
      ..setTranslationRaw(topLeft.dx, topLeft.dy, 0);

    final paint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.decal,
        TileMode.decal,
        matrix.storage,
      );

    canvas
      ..drawRect(
        topLeft & Size(256 * scale.toDouble(), 224 * scale.toDouble()),
        paint,
      )
      ..drawRect(
        (topLeft - const Offset(1, 1)) &
            Size(258 * scale.toDouble(), 226 * scale.toDouble()),
        borderPaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
