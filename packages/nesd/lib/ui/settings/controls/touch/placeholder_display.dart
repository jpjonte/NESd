import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/emulator/display.dart';

class PlaceholderDisplay extends HookWidget {
  const PlaceholderDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final imageState = useState<ui.Image?>(null);
    final imageConfiguration = createLocalImageConfiguration(context);

    useEffect(() {
      const assetImage = AssetImage('assets/placeholder.png');

      final imageStream = assetImage.resolve(imageConfiguration);

      final listener = ImageStreamListener(
        (info, _) => imageState.value = info.image,
      );

      imageStream.addListener(listener);

      return () {
        imageState.value?.dispose();
        imageStream.removeListener(listener);
      };
    }, []);

    final image = imageState.value;

    if (image == null) {
      return const SizedBox();
    }

    return DisplayBuilder.image(image: image);
  }
}
