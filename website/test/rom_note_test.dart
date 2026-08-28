import 'package:nesd_website/components/rom_note.dart';
import 'package:nesd_website/content.dart';
import 'package:test/test.dart';

import 'render.dart';

void main() {
  test('states that NESd ships no game data', () async {
    final html = await renderHtml(const RomNote());

    expect(html, contains('You bring the games'));
    expect(html, contains('ships without games'));
  });

  test('names the file types a newcomer can open', () async {
    final html = await renderHtml(const RomNote());

    expect(html, contains('<code>.nes</code>'));
    expect(html, contains('<code>.zip</code>'));
  });

  test('links every homebrew source with its note', () async {
    final html = await renderHtml(const RomNote());

    for (final source in romSources) {
      expect(html, contains('href="${source.url}"'));
      expect(html, contains('>${source.label}</a>'));
      expect(html, contains(source.note));
    }
  });

  test('anchors the section so the page can link to it', () async {
    final html = await renderHtml(const RomNote());

    expect(html, contains('id="games"'));
  });
}
