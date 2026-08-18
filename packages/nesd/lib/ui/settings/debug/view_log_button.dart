import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/router/router.dart';

class ViewLogButton extends ConsumerWidget {
  const ViewLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FocusOnHover(
      child: ButtonSettingsTile(
        title: const Text('View log'),
        onPressed: () => ref.read(routerProvider).navigate(const LogRoute()),
      ),
    );
  }
}
