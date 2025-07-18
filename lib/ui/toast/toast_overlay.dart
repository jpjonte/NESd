import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/outline_text.dart';
import 'package:nesd/ui/theme/base.dart';
import 'package:nesd/ui/toast/toaster.dart';

class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastStateProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: toasts.length.toDouble()),
        duration: const Duration(milliseconds: 100),
        builder:
            (context, offset, child) => Transform.translate(
              offset: Offset(0, 32 * (toasts.length.toDouble() - offset)),
              child: child,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final toast in toasts)
              ToastWidget(toast, isFirst: toast == toasts.first),
          ],
        ),
      ),
    );
  }
}

class ToastWidget extends ConsumerWidget {
  const ToastWidget(this.toast, {required this.isFirst, super.key});

  final Toast toast;
  final bool isFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final textStyle = themeData.textTheme.bodyLarge!.copyWith(
      fontSize: 18,
      fontVariations: const [FontVariation.weight(700)],
    );

    final color = switch (toast.type) {
      ToastType.info => Colors.blue[800]!,
      ToastType.warning => Colors.orange[800]!,
      ToastType.error => nesdRed[600]!,
    };

    final outlineColor = switch (toast.type) {
      ToastType.info => Colors.blue[100]!,
      ToastType.warning => Colors.orange[100]!,
      ToastType.error => nesdRed[200]!,
    };

    return MouseRegion(
      cursor: WidgetStateMouseCursor.clickable,
      child: GestureDetector(
        onTap: () => ref.read(toasterProvider).dismiss(toast),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: StrokeText(
            toast.message,
            strokeColor: outlineColor,
            style: textStyle.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
