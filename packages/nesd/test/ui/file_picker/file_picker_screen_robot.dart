import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  void expectFilePickerScreenFound() {
    expectOne(find.byType(FilePickerScreen));
  }

  Future<void> focusSearchBar() async {
    await go(_searchField);
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
}
