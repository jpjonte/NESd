# Contributing

Contributions are very welcome! Feel free to grab an existing issue or file a new one.

Open a PR with your proposed changes and I'll check it out as soon as I can.

## Reporting bugs

Please use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml) and include the log.

NESd keeps a rolling log you can read in **Settings → Debug → View log**,
where **Copy all** puts it on the clipboard and **Save to file** writes it
out. The same records are written continuously to `nesd.log` in the
application support directory, so they survive a crash. The exact path is logged
at startup.

## Setup

NESd uses [FVM](https://fvm.app/) for Flutter version management (see `.fvmrc`).

```bash
pushd packages/nesd && fvm flutter pub get && popd
bin/install_hooks.sh          # pre-commit hook: format + analyze
bin/configure_nightly_tag.sh  # allow the rolling `nightly` tag to update
```

The last step is a one-time git config change. Without it, every `git fetch`
fails with `would clobber existing tag` after CI moves the `nightly` tag to
`main`, and the local tag has to be deleted by hand. Pass the remote name as an
argument if yours is not the one `main` tracks.

## Architecture

Three packages: `packages/nesd/` (app + emulator core),
`packages/nesd_texture/` (GPU texture plugin) and `packages/nesd_audio/`
(push-model PCM audio output plugin).

**Emulator core** (`lib/nes/`): `NES` drives the CPU (6502), PPU, APU and a
central `Bus` that routes all memory access. The bus reaches PRG/CHR ROM
through the mappers in `nes/cartridge/mapper/`.

**Isolate boundary** (`lib/nes/isolate/`): The core and audio output run on a
background isolate. The UI never touches `NES` directly. `RemoteNes` is the
UI-side proxy that sends commands and consumes events. Frames cross as native
pointer addresses and are handed back with `ReleaseFrameCommand`. APU samples
are pushed straight from the isolate into nesd_audio through
`audio/audio_output.dart`.

**UI** (`lib/ui/`): Flutter with Riverpod. `nes_controller.dart` owns ROM
loading and isolate lifecycle. `display_controller.dart` receives frames and
renders them via nesd_texture (GPU) or CustomPaint (CPU fallback).

Save states live in `nes/serialization/` (binarize), rewind in `nes/rewind/`.
Settings use Freezed/json_serializable. Rerun codegen after editing them:

```bash
pushd packages/nesd && fvm dart run build_runner build && popd
```

## Code style

`analysis_options.yaml` is the source of truth, `fvm dart format .` handles the
rest. Beyond that:

- 80 character lines; package imports only (`package:nesd/...`).
- `final` by default, `const` constructors where possible.
- Guard clauses and early returns instead of `else` after a `return`.
- Dart 3 pattern matching and switch expressions for compact mappings.
- Cascades (`..`) for several calls on the same receiver.
- Blank lines around control-flow blocks and between unrelated statements.
- Small private helpers (`_name`) kept near their call sites.
- Comments say what the code can't: contracts (units, ranges,
  null-vs-throw, ordering, single-use) and the WHY of non-obvious
  workarounds, naming the concrete constraint in a line or two.
- Never restate the declaration, the language idiom, or the change
  rationale (that belongs in the commit message). If nothing is left
  after that, write no comment.

## Branches and commits

- `feature/<issue>-<slug>` for features, `fix/<issue>-<slug>` for bugfixes;
  omit `<issue>-` if there is no issue.
- Short, imperative commit subjects referencing the issue: `#123 Fix input lag`.
- Update `CHANGELOG.md` under "Unreleased" for user-facing changes.

## Before opening a pull request

```bash
fvm dart format .
pushd packages/nesd && fvm flutter analyze && fvm flutter test && popd
FLUTTER="fvm flutter" ci/0-test/web_test.sh  # browser subset, needs Chrome
```

## Supported game counts

The mapper list and game counts in `README.md`, and `supportedGameCount` in `website/lib/content.dart`, are generated from `assets/nes20db.xml`. After adding a mapper or updating the database, regenerate them:

```bash
pushd packages/nesd && fvm dart run tool/update_game_counts.dart && popd
```

A new mapper needs its display name added to the README list by hand first, the script will tell you if one is missing. `--check` reports drift without writing, for use in CI.

The script counts retail releases, multicarts and plug-and-play devices, and skips homebrew, bootlegs, hacks, prototypes, bad dumps, samples, arcade boards and BIOS images.

## Running on the web

Development loop:

```bash
pushd packages/nesd && fvm flutter run -d chrome
```

For play-testing, run a release build:

```bash
pushd packages/nesd && fvm flutter run -d chrome --release
```

By default `flutter run` uses the JavaScript compiler. Pass `--wasm` to
run the WebAssembly variant that release builds actually ship:

```bash
pushd packages/nesd && fvm flutter run -d chrome --wasm --release
```

Build the WebAssembly release variant (the CDN flag keeps it
self-contained, matching CI):

```bash
fvm flutter build web --wasm --no-web-resources-cdn
```

## Website

`website/` is a standalone Dart package that builds https://nesd.jpj.dev with [jaspr](https://jaspr.site) in static mode.
CI builds and deploys it to GitHub Pages on every push to `main` and after each release.
All commands run from `website/`:

```bash
fvm dart pub get
tool/fetch_release.sh              # latest release → build/release.json (needs gh CLI)
fvm dart run jaspr_cli:jaspr serve # check http://localhost:8080
fvm dart run jaspr_cli:jaspr build --sitemap-domain https://nesd.jpj.dev
                                   # -> build/jaspr/, then tool/stage.sh → build/site/
fvm dart test
```

Download links are generated from the release manifest, and the privacy page from `PRIVACY.md`.
The feature list, screenshots and supported-game count are defined in `website/lib/content.dart`.
