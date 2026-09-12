import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();

    addTearDown(container.dispose);

    container.listen(settingsNavigationProvider, (_, _) {});
  });

  SettingsNavigation notifier() =>
      container.read(settingsNavigationProvider.notifier);

  SettingsNavigationState state() => container.read(settingsNavigationProvider);

  test('starts with no category and no expanded groups', () {
    expect(state().category, isNull);
    expect(state().expandedGroups, isEmpty);
  });

  test('setting the category keeps the expanded groups', () {
    notifier().toggleGroup('controls.bindings.menu');
    notifier().category = SettingsCategory.video;

    expect(state().category, SettingsCategory.video);
    expect(state().expandedGroups, {'controls.bindings.menu'});
  });

  test('step moves forward from General when nothing is selected', () {
    notifier().step(1);

    expect(state().category, SettingsCategory.video);
  });

  test('step wraps around in both directions', () {
    notifier().category = SettingsCategory.advanced;
    notifier().step(1);

    expect(state().category, SettingsCategory.general);

    notifier().step(-1);

    expect(state().category, SettingsCategory.advanced);
  });

  test('toggleGroup expands then collapses', () {
    notifier().toggleGroup('controls.bindings.player1');

    expect(notifier().isExpanded('controls.bindings.player1'), isTrue);

    notifier().toggleGroup('controls.bindings.player1');

    expect(notifier().isExpanded('controls.bindings.player1'), isFalse);
  });

  test('starts with an empty query', () {
    expect(state().query, '');
  });

  test('the query survives category changes and group toggles', () {
    notifier().query = 'start';
    notifier().category = SettingsCategory.video;
    notifier().toggleGroup('controls.bindings.menu');
    notifier().step(1);

    expect(state().query, 'start');
    expect(notifier().query, 'start');
  });

  test('reveal selects the category and expands the group', () {
    final target = settingsEntryLocations.singleWhere(
      (l) => l.id == 'controls.bindings.player2/Controller 2 Start',
    );

    notifier().query = 'player 2 start';
    notifier().toggleGroup('controls.bindings.menu');
    notifier().reveal(target);

    expect(state().category, SettingsCategory.controls);
    expect(notifier().isExpanded('controls.bindings.player2'), isTrue);
    expect(notifier().isExpanded('controls.bindings.menu'), isTrue);
    expect(state().query, 'player 2 start');
  });

  test('reveal of an ungrouped entry only selects the category', () {
    final target = settingsEntryLocations.singleWhere(
      (l) => l.entry.title == 'Auto Save',
    );

    notifier().reveal(target);

    expect(state().category, SettingsCategory.general);
    expect(state().expandedGroups, isEmpty);
  });

  test('states with equal fields are equal', () {
    expect(
      const SettingsNavigationState(
        category: SettingsCategory.audio,
        expandedGroups: {'a'},
        query: 'q',
      ),
      equals(
        const SettingsNavigationState(
          category: SettingsCategory.audio,
          expandedGroups: {'a'},
          query: 'q',
        ),
      ),
    );
    expect(
      const SettingsNavigationState(query: 'a'),
      isNot(equals(const SettingsNavigationState(query: 'b'))),
    );
  });
}
