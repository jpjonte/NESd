import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/navigation/category_focus_nodes.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_nav_pane.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/search/settings_search.dart';

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
    final entryKeys = useMemoized(createEntryKeys);

    final contentFocus = useFocusNode(
      skipTraversal: true,
      debugLabel: 'settings content',
    );

    final categoryFocusNodes = useCategoryFocusNodes('settings nav');
    final paneFocus = useFocusNode(
      skipTraversal: true,
      debugLabel: 'settings pane',
    );
    final resultsFocus = useFocusNode(
      skipTraversal: true,
      debugLabel: 'settings results',
    );
    final lastResult = useRef<String?>(null);

    final navScope = useFocusScopeNode(debugLabel: 'settings nav scope');
    final contentScope = useFocusScopeNode(
      debugLabel: 'settings content scope',
    );

    useEffect(() {
      scheduleMicrotask(() {
        if (!context.mounted) {
          return;
        }

        focusFirstDescendant(
          navigation.query.trim().isNotEmpty
              ? paneFocus
              : categoryFocusNodes[category]!,
        );
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

    void selectEntry(SettingsEntryLocation target) {
      lastResult.value = target.id;
      navigation.reveal(target);

      afterRebuild(() => unawaited(scrollToEntry(entryKeys, target.id)));
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

    void returnToNav() {
      final query = navigation.query;

      if (query.trim().isEmpty) {
        focusFirstDescendant(categoryFocusNodes[category]!);

        return;
      }

      final rows = resultsFocus.traversalDescendants.toList();

      if (rows.isEmpty) {
        focusFirstDescendant(paneFocus);

        return;
      }

      final index = visibleSettingsMatches(
        ref,
        query,
      ).indexWhere((match) => match.id == lastResult.value);

      rows[index < 0 ? 0 : index].requestFocus();
    }

    void enterContent() {
      final last = contentScope.focusedChild;

      if (last != null && last.canRequestFocus) {
        last.requestFocus();

        return;
      }

      focusFirstDescendant(contentFocus);
    }

    void moveFocus(TraversalDirection direction) {
      final focus = FocusManager.instance.primaryFocus;

      if (focus == null || focus.focusInDirection(direction)) {
        return;
      }

      switch (direction) {
        case TraversalDirection.left when contentScope.hasFocus:
          returnToNav();
        case TraversalDirection.right when navScope.hasFocus:
          enterContent();
        default:
        // the pane's wrap policy already handled up and down
      }
    }

    return Actions(
      actions: {
        PreviousTabIntent: CallbackAction<PreviousTabIntent>(
          onInvoke: (_) => step(-1),
        ),
        NextTabIntent: CallbackAction<NextTabIntent>(onInvoke: (_) => step(1)),
        DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: (intent) {
            moveFocus(intent.direction);

            return null;
          },
        ),
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (intent) {
            if (contentScope.hasFocus) {
              returnToNav();

              return null;
            }

            return Actions.maybeInvoke(context, intent);
          },
        ),
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SettingsNavPane.width + contentMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusChild(
                autofocus: false,
                wrapAround: true,
                node: navScope,
                child: Focus(
                  focusNode: paneFocus,
                  skipTraversal: true,
                  child: SettingsNavPane(
                    categoryFocusNodes: categoryFocusNodes,
                    resultsFocusNode: resultsFocus,
                    onSelectCategory: selectCategory,
                    onSelectSection: selectSection,
                    onSelectEntry: selectEntry,
                  ),
                ),
              ),
              Expanded(
                child: FocusChild(
                  autofocus: false,
                  wrapAround: true,
                  node: contentScope,
                  child: Focus(
                    focusNode: contentFocus,
                    skipTraversal: true,
                    child: SingleChildScrollView(
                      key: ValueKey(category),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: SettingsCategoryContent(
                        category: category,
                        sectionKeys: sectionKeys,
                        entryKeys: entryKeys,
                      ),
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
