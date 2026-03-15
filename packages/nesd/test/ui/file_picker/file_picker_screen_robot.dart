import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';

import '../base_robot.dart';

class FilePickerScreenRobot extends BaseRobot {
  FilePickerScreenRobot(super.tester);

  void expectFilePickerScreenFound() {
    expectOne(find.byType(FilePickerScreen));
  }

  void expectParentLinkFound() {
    expectOne(find.byType(ParentTile));
  }

  void expectFilesFound(int count) {
    expect(find.byType(FileTile), findsNWidgets(count));
  }
}
