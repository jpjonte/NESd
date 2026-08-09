# windowed-tools experiment

Spike branch for #243. **Never merges.** Design:
`docs/superpowers/specs/2026-08-09-windowed-tools-experiment-design.md`
(local, git-excluded). Plan:
`docs/superpowers/plans/2026-08-09-windowed-tools-experiment.md`
(local, git-excluded).

## SDK

- Flutter: 3.47.0-1.0.pre-456 (channel master)
- Dart: 3.14.0 (build 3.14.0-108.0.dev)
- Commit: f69633edddff9f9a530c09824e05b6947e854d50
- Pinned as: commit

## Run

    FLUTTER_WINDOWING=true fvm flutter run -d macos
    FLUTTER_WINDOWING=true fvm flutter run -d linux

## Observations

### 2026-08-09 — Task 1: pin the SDK, resolve, analyze, test

- Tagged `macOS`: the exact-commit pin worked — `fvm install
  f69633ed` succeeded on the first try (2:46 to download and set up,
  including a Darwin arm64 Dart SDK download); the `fvm install
  master` channel fallback described as a possibility in the task
  brief was **not** needed. Cache dir: `~/fvm/versions/f69633ed`.
- Tagged `macOS`: `fvm flutter --version` from the worktree confirms
  the pin: Flutter 3.47.0-1.0.pre-456, channel master, revision
  f69633eddd, engine f83ed36e900b2d55891273ff1c7b0cd6ebe970c4
  (2026-08-08), Dart 3.14.0 (build 3.14.0-108.0.dev), DevTools
  2.61.0-dev.0.
- Tagged `architectural`: `fvm flutter pub get` (workspace root)
  resolved cleanly — no constraint had to be loosened, so
  `pubspec.yaml` / `packages/nesd/pubspec.yaml` were not touched. It
  bumped 6 transitive deps in `pubspec.lock` (matcher, meta, test,
  test_api, test_core, vector_math — see below for exact versions).
- **Architectural finding, tagged `architectural`:** `pub get` on this
  dev SDK unconditionally rewrites `analysis_options.yaml`, adding
  `build/**`, `android/**`, `ios/**`, `web/**`, `windows/**`,
  `macos/**`, `linux/**` to `analyzer.exclude` and logging "Upgrading
  analysis_options.yaml to exclude build and platform directories."
  It touched all three packages (nesd, nesd_audio, nesd_texture).
  This is not optional: I reverted `packages/nesd/analysis_options.yaml`
  with `git checkout` and re-ran `fvm flutter analyze` — the implicit
  `pub get` that `flutter analyze` runs put the same exclusions right
  back before analysis even started, still 1 issue found. There is no
  way to observe this dev SDK's raw analyze behavior without the
  rewrite happening first; any project that runs `pub get` or
  `flutter analyze`/`test` on this SDK gets it rewritten automatically.
  Decision: kept the rewritten files and committed them, since
  reverting is not durable and every later task's `pub get` will
  reintroduce the same diff anyway.
- Tagged `architectural`: `fvm flutter analyze` (packages/nesd): 1
  issue, a warning (not an error) — `analysis_options_deprecated_plugins`:
  "Support for legacy plugins is deprecated, and will be removed in
  an upcoming version of Dart" at `analysis_options.yaml:4:3`,
  pointing at the `plugins: [custom_lint]` block. This is new on the
  master SDK and would not appear on stable 3.44.9 — the most
  reportable finding in this file, since it is purely an SDK-version
  effect. No other findings — otherwise the same clean result as on
  stable. Reproduced identically across three separate runs (with and
  without the exclude rewrite present going in).
- `fvm flutter test` (packages/nesd), tagged `architectural`: all 672
  tests passed, 0 failures, 0 skips, run twice (once backgrounded,
  once in the foreground per request) with identical results both
  times. Foreground run: `time` measured 157.25s user, 29.42s system,
  217% cpu, 1:25.85 total wall clock, including a CMake build of
  `libnesd_audio.dylib` — far faster than the "up to ~15 minutes" the
  brief warned about; this machine's CMake toolchain was already
  warm and the build cached between the two runs.
- Tagged `architectural`: `pub get` also bumped 6 transitive deps in
  `pubspec.lock`: matcher 0.12.19→0.12.20, meta 1.18.0→1.19.0,
  test 1.31.0→1.31.1, test_api 0.7.11→0.7.12, test_core
  0.6.17→0.6.18, vector_math 2.2.0→2.4.2. No direct constraint in
  either `pubspec.yaml` needed loosening.
- Net for #244: the 2026-08-08 master SDK resolves the workspace,
  analyzes with only one new deprecation warning (plus the mandatory
  analysis_options.yaml rewrite above), and passes the full existing
  test suite unmodified, twice, in under 2 minutes each run. No
  application code was touched by this task.
