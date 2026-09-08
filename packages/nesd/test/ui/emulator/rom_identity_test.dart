import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

const _romHash = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';
const _otherRomHash = '0f1e2d3c4b5a69788796a5b4c3d2e1f001234567';

RomInfo _rom({
  String path = '/roms/game.nes',
  String name = 'game.nes',
  String? hash,
  String? romHash = _romHash,
}) => RomInfo(
  file: FilesystemFile(path: path, name: name, type: FilesystemFileType.file),
  hash: hash,
  romHash: romHash,
);

void main() {
  group('equality', () {
    test('two ROMs with the same fields are equal', () {
      expect(_rom(), _rom());
      expect(_rom().hashCode, _rom().hashCode);
    });

    test('the same content under a different name is not the same value', () {
      expect(_rom(), isNot(_rom(name: 'The Game (USA).nes')));
    });

    test('different content under the same name is not the same value', () {
      expect(_rom(), isNot(_rom(romHash: _otherRomHash)));
    });

    test('every differing field breaks equality', () {
      expect(_rom(), isNot(_rom(path: '/roms/jp/game.nes')));
      expect(_rom(), isNot(_rom(hash: 'file-hash')));
      expect(_rom(), isNot(_rom(romHash: null)));
    });

    test('equal ROMs agree on their hash code', () {
      // the old operator== matched on any one of name/romHash/hash while
      // hashCode mixed name and romHash, so equal values could land in
      // different buckets of a Set, Map or provider family cache
      final pairs = [
        (_rom(), _rom()),
        (_rom(romHash: null), _rom(romHash: null)),
        (_rom(hash: 'x'), _rom(hash: 'x')),
      ];

      for (final (a, b) in pairs) {
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      }
    });

    test('equality is transitive', () {
      final a = _rom(name: 'a.nes');
      final b = _rom(name: 'b.nes', romHash: _otherRomHash);
      final c = _rom(name: 'b.nes');

      // a and c share a romHash, b and c share a name; under the old
      // or-matching both pairs were equal while a and b were not
      expect(a == c && c == b, isFalse);
    });

    test('a set keeps one entry per distinct ROM', () {
      final set = {_rom(), _rom(), _rom(name: 'other.nes')};

      expect(set, hasLength(2));
    });
  });

  group('sameRom', () {
    test('content wins over the file name', () {
      expect(_rom().sameRom(_rom(name: 'The Game (USA).nes')), isTrue);
      expect(_rom().sameRom(_rom(path: '/roms/jp/game.nes')), isTrue);
    });

    test('two games sharing a file name are not the same ROM', () {
      expect(_rom().sameRom(_rom(romHash: _otherRomHash)), isFalse);
    });

    test('without a content hash the path decides', () {
      expect(_rom(romHash: null).sameRom(_rom(romHash: null)), isTrue);
      expect(
        _rom(
          romHash: null,
        ).sameRom(_rom(path: '/roms/jp/x.nes', romHash: null)),
        isFalse,
      );
    });

    test('a hashed ROM adopts the unhashed entry for the same path', () {
      // legacy recent ROMs carry no romHash; loading one has to replace
      // that entry rather than add a second row for the same game
      expect(_rom().sameRom(_rom(romHash: null)), isTrue);
      expect(_rom(romHash: null).sameRom(_rom()), isTrue);
    });

    test('an unhashed ROM at another path stays distinct', () {
      expect(
        _rom().sameRom(_rom(path: '/roms/jp/x.nes', romHash: null)),
        false,
      );
    });
  });

  group('key', () {
    test('the content hash is the key', () {
      expect(_rom().key, _romHash);
    });

    test('the file hash is the first fallback', () {
      expect(_rom(romHash: null, hash: 'file-hash').key, 'file-hash');
    });

    test('the file name is the last fallback', () {
      expect(_rom(romHash: null).key, 'game.nes');
    });

    test('the key ignores the path so a renamed folder keeps it', () {
      expect(_rom(path: '/elsewhere/game.nes').key, _rom().key);
    });
  });
}
