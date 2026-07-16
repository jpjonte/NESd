# Binary savestate fixtures

`prewiden_vblank.state`, `prewiden_midtile.state`: full-console NESd
savestates written by the LAST pre-field-widening commit,
ROM `roms/test/scanline/scanline.nes`, positions: post-`runFrames(60)`
vblank, and scanline 120 / cycle ≥ 100 mid-tile.

They pin the legacy (PPUState v1 era) on-disk format forever:
`test/nes/serialization/legacy_savestate_fixture_test.dart` loads them and
asserts replay hashes captured at generation time. NEVER regenerate these
files — a regenerated fixture would silently pin the new format instead.
