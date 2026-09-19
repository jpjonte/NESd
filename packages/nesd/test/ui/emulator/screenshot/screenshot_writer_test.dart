import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_writer.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('nesd_screenshots');

    addTearDown(() => temp.deleteSync(recursive: true));
  });

  test('writes into the directory, creating it on demand', () async {
    final directory = p.join(temp.path, 'Pictures', 'NESd');
    final writer = NativeScreenshotWriter(directory: () async => directory);

    final location = await writer.write(
      'game.png',
      Uint8List.fromList([1, 2, 3]),
    );

    expect(File(p.join(directory, 'game.png')).readAsBytesSync(), [1, 2, 3]);
    expect(location, endsWith(p.join('Pictures', 'NESd', 'game.png')));
  });

  test('never overwrites an existing screenshot', () async {
    final writer = NativeScreenshotWriter(directory: () async => temp.path);

    for (var i = 0; i < 3; i++) {
      await writer.write('game.png', Uint8List.fromList([i]));
    }

    expect(File(p.join(temp.path, 'game.png')).readAsBytesSync(), [0]);
    expect(File(p.join(temp.path, 'game (2).png')).readAsBytesSync(), [1]);
    expect(File(p.join(temp.path, 'game (3).png')).readAsBytesSync(), [2]);
  });

  test('the Linux pictures folder follows user-dirs.dirs', () {
    expect(
      linuxPicturesDirectory(
        home: '/home/buddy',
        userDirs:
            '# comment\n'
            'XDG_DESKTOP_DIR="\$HOME/Schreibtisch"\n'
            'XDG_PICTURES_DIR="\$HOME/Bilder"\n',
      ),
      '/home/buddy/Bilder',
    );

    expect(
      linuxPicturesDirectory(
        home: '/home/buddy',
        userDirs: 'XDG_PICTURES_DIR=/mnt/photos\n',
      ),
      '/mnt/photos',
    );

    expect(linuxPicturesDirectory(home: '/home/buddy'), '/home/buddy/Pictures');
  });

  test('paths under the home directory display with a tilde', () {
    expect(
      displayPath('/Users/buddy/Pictures/NESd/game.png', home: '/Users/buddy'),
      '~/Pictures/NESd/game.png',
    );

    expect(displayPath('/tmp/game.png', home: '/Users/buddy'), '/tmp/game.png');
  });
}
