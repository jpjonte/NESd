import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/hooks/use_context_menu_controller.dart';

typedef ContextMenuBuilder = List<Widget> Function(BuildContext, VoidCallback);

class ContextMenu extends HookWidget {
  const ContextMenu({required this.contextMenuBuilder, this.child});

  final ContextMenuBuilder? contextMenuBuilder;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = useContextMenuController();

    final offset = useState(Offset.zero);

    void close() {
      ContextMenuController.removeAny();
    }

    if (contextMenuBuilder == null) {
      return child ?? const SizedBox();
    }

    void open(Offset offset) {
      controller.show(
        context: context,
        contextMenuBuilder:
            (context) => ListTileTheme(
              data: const ListTileThemeData(
                titleTextStyle: TextStyle(fontSize: 13),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                minTileHeight: 12,
              ),
              child: CustomSingleChildLayout(
                delegate: DesktopTextSelectionToolbarLayoutDelegate(
                  anchor: offset,
                ),
                child: TapRegion(
                  onTapOutside: (_) => close(),
                  child: SizedBox(
                    width: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Material(
                        child: Builder(
                          builder:
                              (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: contextMenuBuilder!(context, close),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) => offset.value = details.globalPosition,
      onLongPress: () => open(offset.value),
      onSecondaryTapUp: (details) => open(details.globalPosition),
      child: child,
    );
  }
}
