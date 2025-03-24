import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FocusChild extends HookWidget {
  const FocusChild({required this.child, required this.autofocus, super.key});

  final Widget child;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final focusScopeNode = useFocusScopeNode();

    useEffect(() {
      if (autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusScopeNode.descendants
              .firstWhereOrNull((d) => d.canRequestFocus)
              ?.requestFocus();
        });
      }

      return null;
    }, [autofocus]);

    return FocusScope(node: focusScopeNode, child: child);
  }
}
