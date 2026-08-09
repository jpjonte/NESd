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

### 2026-08-10 — Task 2: windowed bootstrap on the stock macOS runner

- Tagged `architectural`: the plan's `WindowManager`/`WindowEntry`/
  `WindowController`/`WindowControllerDelegate` surface transcribed
  verbatim against the pinned SDK (`f69633ed`) — no API adaptation
  was forced. Verified each signature directly in
  `$FVM_SDK/packages/flutter/lib/src/widgets/_window.dart` and
  `_features.dart` before writing the code:
  `WindowController({required Size size, BoxConstraints? constraints,
  String? title, WindowControllerDelegate? delegate})` is a factory
  that creates the native window on construction;
  `WindowEntry({required BaseWindowController controller, required
  WidgetBuilder builder})`; `WindowManager({required
  List<WindowEntry> initialWindows})`; `mixin class
  WindowControllerDelegate` exposes `onWindowCloseRequested` and
  `onWindowDestroyed`. `main.dart` now hoists the `overrides` list to
  a local, branches on `isWindowingEnabled` between `runApp` (with
  `return`) and `runWidget` + `WindowManager`, and defines
  `MainWindowDelegate` at the bottom of the file, calling `exit(0)`
  from `onWindowDestroyed`. `fvm dart format .` collapsed two of the
  brief's multi-line expressions (the
  `applicationSupportPathProvider.overrideWithValue(...)` call and
  the `BoxConstraints(minWidth: ..., minHeight: ...)` literal) onto a
  single line each — both fit under 80 columns as one-liners; this is
  ordinary formatter output, not a content change from the brief.
- Tagged `architectural`: `fvm flutter analyze` (packages/nesd) came
  back with exactly the one pre-existing warning carried over from
  Task 1 (`analysis_options_deprecated_plugins` at
  `analysis_options.yaml:4:3`) and nothing attributable to
  `main.dart` — the `// ignore_for_file: implementation_imports,
  invalid_use_of_internal_member` header suppresses the `@internal`
  and `implementation_imports` lint on the windowing imports as
  intended.
- Tagged `macOS`: `fvm flutter build macos --debug --flavor dev`
  (windowing off) succeeded — `✓ Built
  build/macos/Build/Products/Debug-dev/NESd.app` — in 61.5s wall
  clock (10.69s user, 3.06s system), including a `pod install` step
  since this was the first build of the session. A bare `flutter
  build macos --debug` with no `--flavor` fails before touching our
  code, on either build, with `Unable to find expected configuration
  in Xcode project.` (`flutter_tools/src/macos/build_macos.dart:164`)
  — this project defines `dev`/`prod` flavors (`Debug-dev`,
  `Debug-prod`, ... configurations; confirmed against
  `ci/1-build/macos/build.sh`, which always passes `--flavor`), so an
  unflavored build has no matching Xcode configuration to select.
  Preexisting project shape, unrelated to windowing; adding
  `--flavor dev` was enough.
- Tagged `macOS`: `FLUTTER_WINDOWING=true fvm flutter build macos
  --debug --flavor dev` (windowing on) also succeeded — `✓ Built
  build/macos/Build/Products/Debug-dev/NESd.app` — in 39.1s wall
  clock (11.04s user, 3.29s system); faster than the first build only
  because pods were already installed and CocoaPods/Xcode caches were
  warm, not because of the flag itself. Diffing the two build logs
  (deduped of the `pub get` outdated-package banner) shows no
  observable difference in build *output* attributable to the flag
  — no mention of "windowing" or "feature" in either log; the only
  differences are the one-time `pod install` line and a "Run Script
  phase" warning present only in the first (cold) build. The flag is
  read by `flutter_tools/src/features.dart:260`
  (`environmentOverride: 'FLUTTER_WINDOWING'`), which flips a
  compile-time constant baked into the built app rather than
  producing tool-visible output, so the only way to observe its
  effect is at runtime.
- Tagged `architectural`: the first `flutter build macos` on this
  pinned SDK auto-upgraded `macos/Podfile`,
  `macos/Runner.xcodeproj/project.pbxproj`, and the `Runner.xcscheme`
  (deployment target bump to 12.0, Swift Package Manager
  integration) — logged as "Upgrading project.pbxproj" / "Upgrading
  Podfile" / "Adding Swift Package Manager integration". Same shape
  as Task 1's `analysis_options.yaml` finding: the tool rewrites
  project files as a side effect of the SDK bump, not of this task's
  code. Per this task's file-scope constraint, those four files were
  reverted with `git checkout --` after both builds completed
  successfully; the builds themselves are unaffected by the revert
  since `build/` output is untracked. A later task that runs `flutter
  build macos` again will hit the same rewrite.
- Pending user run: docked boot check (plan Task 2 step 4).
- Pending user run: windowed run on stock runner (plan Task 2 step 5).
