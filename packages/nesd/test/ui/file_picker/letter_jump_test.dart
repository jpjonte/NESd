import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/letter_jump.dart';

LetterJumpEntry _file(String name, {bool focusable = true}) =>
    (name: name, isDirectory: false, focusable: focusable);

LetterJumpEntry _directory(String name) =>
    (name: name, isDirectory: true, focusable: true);

void main() {
  group('letterJump', () {
    final plain = [
      _file('Alpha.nes'),
      _file('Aztec.nes'),
      _file('Bubble.nes'),
      _file('Bobble.nes'),
      _file('Castle.nes'),
    ];

    test('jumps forward to the first entry of the next group', () {
      final target = letterJump(plain, currentIndex: 0, forward: true);

      expect(target, (index: 2, group: 'B'));
    });

    test('jumps backward to the start of the current group', () {
      final target = letterJump(plain, currentIndex: 3, forward: false);

      expect(target, (index: 2, group: 'B'));
    });

    test('jumps backward to the previous group from a group start', () {
      final target = letterJump(plain, currentIndex: 2, forward: false);

      expect(target, (index: 0, group: 'A'));
    });

    test('groups case-insensitively', () {
      final entries = [
        _file('alpha.nes'),
        _file('Aztec.nes'),
        _file('bubble.nes'),
      ];

      final target = letterJump(entries, currentIndex: 0, forward: true);

      expect(target, (index: 2, group: 'B'));
    });

    test('groups by the first character after a shared prefix', () {
      final entries = [
        _file('Solar Jetman.nes'),
        _file('Star Fox.nes'),
        _file('Super Mario.nes'),
      ];

      final target = letterJump(entries, currentIndex: 0, forward: true);

      expect(target, (index: 1, group: 'ST'));
    });

    test('includes the shared prefix when jumping backward', () {
      final entries = [
        _directory('Saves'),
        _file('Solar Jetman.nes'),
        _file('Star Fox.nes'),
      ];

      final target = letterJump(entries, currentIndex: 2, forward: false);

      expect(target, (index: 1, group: 'SO'));
    });

    test('includes shared prefixes longer than one character', () {
      final entries = [
        _file('Mega Man 1.nes'),
        _file('Mega Man 2.nes'),
        _file('Mega Man X.nes'),
      ];

      final target = letterJump(entries, currentIndex: 0, forward: true);

      expect(target, (index: 1, group: 'MEGA MAN 2'));
    });

    test('directories and files form separate groups', () {
      final entries = [
        _directory('Alpha'),
        _directory('Beta'),
        _file('Alpha.nes'),
        _file('Beta.nes'),
      ];

      final target = letterJump(entries, currentIndex: 1, forward: true);

      expect(target, (index: 2, group: 'A'));
    });

    test('lands on the first focusable entry of the target group', () {
      final entries = [
        _file('Alpha.nes'),
        _file('Bubble.txt', focusable: false),
        _file('Bobble.nes'),
      ];

      final target = letterJump(entries, currentIndex: 0, forward: true);

      expect(target, (index: 2, group: 'B'));
    });

    test('skips groups without focusable entries', () {
      final entries = [
        _file('Alpha.nes'),
        _file('Bio.txt', focusable: false),
        _file('Castle.nes'),
      ];

      final target = letterJump(entries, currentIndex: 0, forward: true);

      expect(target, (index: 2, group: 'C'));
    });

    test('skips unfocusable entries when jumping backward', () {
      final entries = [
        _file('Alpha.txt', focusable: false),
        _file('Aztec.nes'),
        _file('Bubble.nes'),
      ];

      final target = letterJump(entries, currentIndex: 2, forward: false);

      expect(target, (index: 1, group: 'A'));
    });

    test('returns null when there is no later group', () {
      final target = letterJump(plain, currentIndex: 4, forward: true);

      expect(target, isNull);
    });

    test('returns null at the first focusable entry going backward', () {
      final target = letterJump(plain, currentIndex: 0, forward: false);

      expect(target, isNull);
    });

    test('enters the list from above on a forward jump', () {
      final target = letterJump(plain, currentIndex: -1, forward: true);

      expect(target, (index: 0, group: 'A'));
    });

    test('returns null for a backward jump from above the list', () {
      final target = letterJump(plain, currentIndex: -1, forward: false);

      expect(target, isNull);
    });

    test('returns null for an empty list', () {
      final target = letterJump(const [], currentIndex: 0, forward: true);

      expect(target, isNull);
    });

    test('returns null for a single entry', () {
      final target = letterJump(
        [_file('Alpha.nes')],
        currentIndex: 0,
        forward: true,
      );

      expect(target, isNull);
    });

    test('returns an empty group when the prefix spans a whole name', () {
      final target = letterJump(
        [_file('Alpha.nes')],
        currentIndex: -1,
        forward: true,
      );

      expect(target, (index: 0, group: ''));
    });
  });

  group('nearestFocusable', () {
    final entries = [
      _file('Alpha.nes'),
      _file('Bubble.txt', focusable: false),
      _file('Castle.txt', focusable: false),
    ];

    test('returns the start index when it is focusable', () {
      expect(nearestFocusable(entries, 0, direction: 1), 0);
    });

    test('scans in the given direction', () {
      expect(nearestFocusable(entries, 1, direction: -1), 0);
    });

    test('returns null when no focusable entry exists in the direction', () {
      expect(nearestFocusable(entries, 1, direction: 1), isNull);
    });
  });
}
