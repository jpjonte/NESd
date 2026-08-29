import 'package:flutter/widgets.dart';
import 'package:nesd/ui/emulator/overscan.dart';

class OverscanCrop extends StatelessWidget {
  const OverscanCrop({
    required this.overscan,
    required this.imageWidth,
    required this.imageHeight,
    required this.child,
    super.key,
  });

  final Overscan overscan;
  final int imageWidth;
  final int imageHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (overscan == Overscan.none) {
      return child;
    }

    return ClipRect(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final scaleX =
              constraints.maxWidth / overscan.visibleWidth(imageWidth);
          final scaleY =
              constraints.maxHeight / overscan.visibleHeight(imageHeight);

          return Stack(
            alignment: Alignment.topLeft,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -overscan.left * scaleX,
                top: -overscan.top * scaleY,
                width: imageWidth * scaleX,
                height: imageHeight * scaleY,
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}
