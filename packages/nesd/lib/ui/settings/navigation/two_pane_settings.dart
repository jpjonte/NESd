import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/navigation/category_focus_nodes.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

class TwoPaneSettings extends HookConsumerWidget {
  const TwoPaneSettings({super.key});

  static const contentMaxWidth = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category =
        ref.watch(settingsNavigationProvider.select((s) => s.category)) ??
        SettingsCategory.general;
    final navigation = ref.read(settingsNavigationProvider.notifier);

    final sectionKeys = useMemoized(createSectionKeys);

    final contentFocus = useFocusNode(
      skipTraversal: true,
      debugLabel: 'settings content',
    );

    final categoryFocusNodes = useCategoryFocusNodes('settings nav');

    useEffect(() {
      scheduleMicrotask(() {
        if (context.mounted) {
          focusFirstDescendant(categoryFocusNodes[category]!);
        }
      });

      return null;
    }, [categoryFocusNodes]);

    void afterRebuild(VoidCallback callback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          callback();
        }
      });
    }

    void selectCategory(SettingsCategory selected) {
      navigation.category = selected;

      afterRebuild(() => focusFirstDescendant(contentFocus));
    }

    void selectSection(SettingsCategory selected, String sectionId) {
      navigation.category = selected;

      afterRebuild(() => unawaited(scrollToSection(sectionKeys, sectionId)));
    }

    void step(int delta) {
      navigation.step(delta);

      focusFirstDescendant(categoryFocusNodes[navigation.category]!);

      afterRebuild(() {
        final focused = FocusManager.instance.primaryFocus?.context;

        if (focused != null) {
          unawaited(Scrollable.ensureVisible(focused));
        }
      });
    }

    return Actions(
      actions: {
        PreviousTabIntent: CallbackAction<PreviousTabIntent>(
          onInvoke: (_) => step(-1),
        ),
        NextTabIntent: CallbackAction<NextTabIntent>(onInvoke: (_) => step(1)),
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SettingsNavPane.width + contentMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsNavPane(
                categoryFocusNodes: categoryFocusNodes,
                onSelectCategory: selectCategory,
                onSelectSection: selectSection,
              ),
              Expanded(
                child: Focus(
                  focusNode: contentFocus,
                  skipTraversal: true,
                  child: SingleChildScrollView(
                    key: ValueKey(category),
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SettingsCategoryContent(
                      category: category,
                      sectionKeys: sectionKeys,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
