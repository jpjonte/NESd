# 7z archive fixtures

Produced by the reference `7z` CLI, not by a Dart encoder. Reading them
back checks `SevenZipFilesystem` against real 7-Zip output.

| File | Contents | Codec | Notes |
| --- | --- | --- | --- |
| `single_rom.7z` | `nestest.nes` | LZMA2 | the CLI default |
| `solid_roms.7z` | `nestest.nes`, `scanline.nes` | LZMA2 | solid |
| `lzma1.7z` | `nestest.nes`, `scanline.nes` | LZMA1 | solid |
| `copy.7z` | `nestest.nes` | stored | |
| `bcj.7z` | `nestest.nes` | LZMA2 | BCJ filter chain |
| `hdr.7z` | `nestest.nes` | LZMA2 | compressed header |
| `dirs.7z` | two ROMs under `nested/` | LZMA2 | directory entries |
| `ppmd.7z` | `nestest.nes` | PPMd | unsupported on purpose |

`solid_roms.7z` is the one that matters most: in a solid archive the entries
share one compressed stream, so pulling out a single ROM means decoding the
whole block. `ppmd.7z` covers a codec the reader deliberately does not
implement: it lists fine and fails at read time, which is the path that has
to surface a `NesdException`.

The ROMs are the ones already in `roms/test/`, so tests can assert the
extracted bytes match the originals exactly.

Regenerate from the repository root with:

```sh
cd $(mktemp -d)
cp <repo>/roms/test/nestest/nestest.nes .
cp <repo>/roms/test/scanline/scanline.nes .
mkdir -p nested/sub
cp nestest.nes nested/sub/
cp scanline.nes nested/
7z a single_rom.7z nestest.nes
7z a solid_roms.7z nestest.nes scanline.nes
7z a -m0=LZMA lzma1.7z nestest.nes scanline.nes
7z a -m0=Copy copy.7z nestest.nes
7z a -m0=BCJ -m1=LZMA2 bcj.7z nestest.nes
7z a -mhc=on -mhe=off hdr.7z nestest.nes
7z a -r dirs.7z nested
7z a -m0=PPMd ppmd.7z nestest.nes
```
