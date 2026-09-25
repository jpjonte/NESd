import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_rom_link.dart';
import 'package:nesd/ui/emulator/rom_link/rom_link.dart';

void main() {
  final page = Uri.parse('https://nesd.jpj.dev/play/');

  RomLink parse(String query) =>
      RomLink.fromPage(page.replace(query: query.isEmpty ? null : query));

  group('RomLink.fromPage', () {
    test('keeps an absolute URL', () {
      final link = parse('rom=https://example.com/game.nes');

      expect(link.url, Uri.parse('https://example.com/game.nes'));
      expect(link.slot, isNull);
      expect(link.invalidSlot, isNull);
    });

    test('resolves a relative path against the page', () {
      final link = parse('rom=library/game.nes');

      expect(link.url, Uri.parse('https://nesd.jpj.dev/play/library/game.nes'));
    });

    test('resolves a root-relative path against the origin', () {
      final link = parse('rom=/library/game.nes');

      expect(link.url, Uri.parse('https://nesd.jpj.dev/library/game.nes'));
    });

    test('decodes an encoded URL', () {
      final link = parse(
        'rom=${Uri.encodeQueryComponent('https://example.com/a b.nes?v=1')}',
      );

      expect(link.url, Uri.parse('https://example.com/a%20b.nes?v=1'));
    });

    test('reads a valid slot', () {
      expect(parse('rom=game.nes&slot=0').slot, 0);
      expect(parse('rom=game.nes&slot=9').slot, 9);
    });

    test('flags a slot outside 0-9 or not a number', () {
      for (final slot in ['10', '-1', 'one', '']) {
        final link = parse('rom=game.nes&slot=$slot');

        expect(link.slot, isNull, reason: slot);
        expect(link.invalidSlot, slot, reason: slot);
      }
    });

    test('rejects a page without a rom parameter', () {
      expect(() => parse(''), throwsA(isA<InvalidRomLink>()));
      expect(() => parse('rom='), throwsA(isA<InvalidRomLink>()));
    });

    test('rejects schemes other than http and https', () {
      for (final rom in [
        'data:application/octet-stream;base64,AAAA',
        'blob:https://nesd.jpj.dev/1234',
        'file:///roms/game.nes',
        'javascript:alert(1)',
      ]) {
        expect(
          () => parse('rom=${Uri.encodeQueryComponent(rom)}'),
          throwsA(isA<InvalidRomLink>()),
          reason: rom,
        );
      }
    });

    test('rejects a malformed URL', () {
      expect(
        () => parse('rom=${Uri.encodeQueryComponent('http://[::1')}'),
        throwsA(isA<InvalidRomLink>()),
      );
    });
  });
}
