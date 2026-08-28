import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_list.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';

import '../base_robot.dart';

class FilePickerScreenRobot extends BaseRobot {
  FilePickerScreenRobot(super.tester);

  Finder get _searchField => find.descendant(
    of: find.byType(SearchBox),
    matching: find.byType(EditableText),
  );

  bool get _searchBarHasFocus =>
      tester.widget<EditableText>(_searchField).focusNode.hasFocus;

  String? get focusedFileName => tester
      .binding
      .focusManager
      .primaryFocus
      ?.context
      ?.findAncestorWidgetOfExactType<FileTile>()
      ?.file
      .name;

  void expectFilePickerScreenFound() {
    expectOne(find.byType(FilePickerScreen));
  }

  Future<void> focusSearchBar() async {
    await go(_searchField);
  }

  Future<void> enterFilter(String text) async {
    await tester.enterText(_searchField, text);
    await fixAsync();
  }

  void expectSearchBarFocused() {
    expect(_searchBarHasFocus, isTrue);
  }

  void expectSearchBarNotFocused() {
    expect(_searchBarHasFocus, isFalse);
  }

  void expectParentLinkFound() {
    expectOne(find.byType(ParentTile));
  }

  void expectFilesFound(int count) {
    expect(find.byType(FileTile), findsNWidgets(count));
  }

  Future<void> focusFile(String name) async {
    final tile = find.byWidgetPredicate(
      (widget) => widget is FileTile && widget.file.name == name,
    );

    expectOne(tile);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(tile));
    await tester.pump();
    await gesture.removePointer();
    await tester.pump();
  }

  void expectFocusedFile(String name) {
    expect(focusedFileName, name);
  }

  Future<void> waitForFocusedFile(String name) async {
    for (var i = 0; i < 20 && focusedFileName != name; i++) {
      await fixAsync();
    }

    expectFocusedFile(name);
  }

  Future<void> waitForDirectory(String label) async {
    final finder = find.descendant(
      of: find.byType(DirectoryPickerButton),
      matching: find.text(label),
    );

    for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
      await fixAsync();
    }

    expectOne(finder);
  }

  Future<void> tapParentTile() async {
    await goAsync(find.byType(ParentTile));
  }

  Future<void> tapDirectoryButton() async {
    await goAsync(find.byType(DirectoryPickerButton));
  }

  AnimatedOpacity? _indicatorFor(String text) {
    final finder = find.ancestor(
      of: find.text(text),
      matching: find.byType(AnimatedOpacity),
    );

    if (finder.evaluate().isEmpty) {
      return null;
    }

    return tester.widget<AnimatedOpacity>(finder.first);
  }

  void expectIndicator(String text) {
    final indicator = _indicatorFor(text);

    expect(indicator, isNotNull, reason: 'no indicator showing "$text"');
    expect(indicator!.opacity, 1);
  }

  void expectIndicatorHidden(String text) {
    final indicator = _indicatorFor(text);

    expect(indicator, isNotNull, reason: 'no indicator holding "$text"');
    expect(indicator!.opacity, 0);
  }

  void expectFileTileVisible(String name) {
    final tile = find.byWidgetPredicate(
      (widget) => widget is FileTile && widget.file.name == name,
    );

    expectOne(tile);

    final rect = tester.getRect(tile);
    final screen = tester.getRect(find.byType(FilePickerScreen));

    expect(screen.top <= rect.top && rect.bottom <= screen.bottom, isTrue);
  }

  int get visibleRowCount {
    final height = tester.getSize(find.byType(CustomScrollView)).height;

    final itemExtent = tester
        .widget<SliverFixedExtentList>(find.byType(SliverFixedExtentList))
        .itemExtent;

    return height ~/ itemExtent;
  }
}
