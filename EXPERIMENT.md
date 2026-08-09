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

### 2026-08-09 — Task 3: macOS runner surgery and the GPU display path

- Tagged `macOS`: the runner had to become engine-owned.
  `AppDelegate.applicationDidFinishLaunching` now constructs a
  headless `FlutterEngine(name: "nesd", project:)`, calls
  `engine.run(withEntrypoint: nil)`, and hands the engine itself to
  `RegisterGeneratedPlugins(registry: engine)` — the generated
  registrant (`macos/Flutter/GeneratedPluginRegistrant.swift`, not
  edited) already takes a `FlutterPluginRegistry`, a protocol
  `FlutterEngine` satisfies, so no regen was needed. In
  `MainMenu.xib`, deleted the `<window id="QvC-M9-y7g"
  customClass="MainFlutterWindow">` element (contentView, constraints,
  `canvasLocation`) and the `mainFlutterWindow` outlet line from the
  `AppDelegate` custom object's connections. Verified zero `<window`
  elements remain and only `delegate`/`applicationMenu` outlets
  survive, matching the shape of Flutter's own
  `dev/integration_tests/windowing_test` reference xib.
- Tagged `macOS`: `MainFlutterWindow.swift` is now orphaned — it
  stays on disk and in the Xcode target (per plan, no
  `project.pbxproj` target surgery), just unreferenced by
  `AppDelegate` and never instantiated.
- Tagged `macOS`: entrypoint-arguments answer — yes, exposed.
  `FlutterDartProject.h` (pinned engine artifacts,
  `darwin-x64/FlutterMacOS.xcframework/macos-arm64_x86_64/
  FlutterMacOS.framework/Versions/A/Headers/FlutterDartProject.h`)
  declares:
  `@property(nonatomic, nullable, copy) NSArray<NSString*>*
  dartEntrypointArguments API_UNAVAILABLE(ios);`
  documented as defaulting to `[NSProcessInfo arguments]` minus the
  binary name when left unset. Wired it per the brief: construct
  `FlutterDartProject()`, set `.dartEntrypointArguments =
  Array(CommandLine.arguments.dropFirst())`, pass it as
  `FlutterEngine(name:project:)`'s `project:`. Cross-checked against
  the engine's own Objective-C source
  (`FlutterDartProject.mm:45-66`, present in this pinned checkout):
  the default `init` already seeds `_dartEntrypointArguments` from
  `NSProcessInfo` with the binary name dropped, so the explicit Swift
  wiring is redundant with that default but makes the ROM-path
  argument delivery visible and intentional rather than relying on
  implicit Objective-C default-init behavior. Not runtime-verified
  (see pending line below) — #244 can treat this as answered but
  untested.
- Tagged `architectural`: auto-upgrade recurrence test, same method
  Task 1 applied to `analysis_options.yaml`. Starting from a clean
  `Podfile`/`Podfile.lock`/`project.pbxproj` (Task 2 had reverted
  them), built with `FLUTTER_WINDOWING=true` — the rewrite fired
  again (`Updating minimum macOS deployment target to 12.0` /
  `Upgrading project.pbxproj` / `Upgrading Podfile`: `platform :osx`
  bumped 10.15→12.0 in the Podfile, `PODFILE CHECKSUM` and the
  `FlutterMacOS` spec checksum updated in Podfile.lock,
  `MACOSX_DEPLOYMENT_TARGET` bumped 10.15→12.0 in all 6 build
  configurations in project.pbxproj — 9 lines across 3 files, no
  Swift Package Manager section added this time since the target's
  pbxproj already carries SPM integration from before this branch).
  Reverted those 3 files again and built a second time without the
  flag: the identical 9-line rewrite recurred verbatim. Verdict:
  forced-and-recurring, same class of finding as
  `analysis_options.yaml` — committed `Podfile`, `Podfile.lock`, and
  `project.pbxproj` in this task's commit rather than fighting a
  rewrite that would just reappear on every later task's build.
  `Runner.xcscheme` (the fourth file Task 2 flagged) was **not**
  touched by either of this task's builds — its earlier rewrite did
  not recur here, so it was left alone (already at HEAD, nothing to
  revert or commit).
- Tagged `macOS`: both required builds succeeded.
  `FLUTTER_WINDOWING=true fvm flutter build macos --debug --flavor
  dev`: 34.3s wall clock (10.22s user, 3.29s system) — `✓ Built
  build/macos/Build/Products/Debug-dev/NESd.app`. `fvm flutter build
  macos --debug --flavor dev` (no flag): 26.8s wall clock (9.82s
  user, 2.76s system) — same success output. No Swift compiler
  errors or warnings attributable to `AppDelegate.swift` or the xib
  change in either build; the brief's AppDelegate code compiled
  without adaptation. Confirms the runner change is flag-independent
  — the engine is constructed unconditionally in
  `applicationDidFinishLaunching`.
- Tagged `macOS`: docked-path asymmetry, a known property of this
  runner shape, not a bug. Without `FLUTTER_WINDOWING`, Dart's
  `main.dart` takes the plain `runApp` branch and never touches
  `runWidget`/`WindowManager` — but the runner no longer creates a
  window either, since `MainFlutterWindow.swift` is orphaned and
  `AppDelegate` never instantiates any `FlutterViewController` or
  `NSWindow`. So the docked (non-windowing) build on this
  engine-owned runner likely opens with **zero** windows, not the one
  it used to get for free from the stock runner — `runApp` on macOS
  has always depended on the platform runner supplying a window to
  render into, and this runner no longer supplies one regardless of
  the flag. That means the meaningful "docked control case" (one
  native window, no windowing API involved) now lives at Task 2's
  commit `536d4ade` (stock runner, `FLUTTER_WINDOWING` unset) rather
  than anywhere on this branch's head. Not run interactively; see
  pending line below.
- Tagged `macOS`: the GPU display path (`nesd_texture`,
  `NesdTexturePlugin.register(with:)` / `registrar.textures`) was not
  touched — reviewed but not modified. `RegisterGeneratedPlugins`
  hands each plugin a registrar from `engine.registrar(forPlugin:)`,
  so `registrar.textures` now resolves against the engine's texture
  registry rather than one scoped to a view controller the runner
  used to own; whether that registry is still reachable by whatever
  view ends up hosting the `Texture` widget under `WindowManager` is
  a runtime question this task did not answer, per the division of
  labor (Step 5 is an interactive verification left to the user, and
  the design decision is fix-here over CPU-painter fallback, which
  only applies once the texture path is confirmed broken).
- Pending user run: single-window check + GPU display path (plan
  Task 3 steps 4-5).
- Pending user run: nesd_texture verdict gates the fix-don't-fall-back
  decision.

### 2026-08-09 — Task 4: `WindowedToolHost`, `ToolWindow`, and host selection

- Tagged `architectural`: both new files
  (`lib/ui/emulator/tools/windowed_tool_host.dart`,
  `lib/ui/emulator/tools/tool_window.dart`) transcribed from the brief
  with registration/unregistration kept out of `build` as designed —
  `WindowedToolHost.build` only ever *defines* the local `sync`
  closure; the only two call sites are the `useEffect(..., const [])`
  post-frame callback (`WidgetsBinding.instance
  .addPostFrameCallback((_) => sync(open))`, so the first sync happens
  after the first frame, not during it) and the `ref.listen(...)`
  callback (which Riverpod invokes outside build, on state changes).
  `registry.register`/`registry.unregister` and
  `entry.controller.destroy()` are therefore only ever reached from
  those two callbacks, never synchronously inside `build`. Preserved
  the brief's comment on `_close` explaining the
  unregister-before-destroy order.
- **Compiler-forced adaptation, tagged `architectural`:** the brief's
  interface list claimed `EmulatorTool.contentWidth` /
  `EmulatorTool.minHeight` were "verified present on this branch" —
  false for this branch. `lib/ui/emulator/tools/emulator_tool.dart`
  here still has only `title` (last touched by `95915ca7 #243 Extract
  tool widths to named constants`, itself pre-dating this experiment).
  `dart analyze` on the brief's literal code confirmed it:
  `windowed_tool_host.dart:57:23 - The getter 'contentWidth' isn't
  defined for the type 'EmulatorTool'. ... - undefined_getter` (and
  the same for `minHeight` at 57:42 and `contentWidth` again at
  59:24). Those two members were added later, upstream, by `main`
  commit `95c343b3` ("#296 Register tool sizes in registry" —
  confirmed an ancestor of `main` and of
  `feature/251-gamepads-upstream`, confirmed **not** an ancestor of
  this branch via `git merge-base --is-ancestor`): this experiment
  branched off `main` at `bef1bd93`, before `95c343b3` landed, and per
  the plan's Global Constraints never merges, so it will never pick
  that commit up. `emulator_tool.dart` is on the do-not-modify list,
  so rather than adding the members there, `tool_window.dart` gains
  two local top-level functions, `toolContentWidth(EmulatorTool)` and
  `toolMinHeight(EmulatorTool)`, reproducing the exact per-tool values
  from `95c343b3` (`contentWidth`: 512 for every tool except
  `executionLog`, which uses the existing `executionLogWidth` = 560;
  `minHeight`: tileViewer 480, cartridgeInfo 372, apuDebug 408,
  debugger 400, executionLog 400) — not invented, transcribed from
  that commit's diff. `windowed_tool_host.dart` calls these instead of
  `tool.contentWidth`/`tool.minHeight` (it already imports
  `tool_window.dart` for `ToolWindow`, so no new import was needed).
  `emulator_tool.dart` itself was not touched — confirmed by `git
  status --short` showing no change to it.
- Tagged `architectural`: two more `flutter analyze` findings, both
  fixed inside the brief's own files rather than suppressed: (1)
  `directives_ordering` on `main.dart`'s new
  `windowed_tool_host.dart` import — resorted alphabetically ahead of
  `file_picker/...` and after `emulator/rom_manager.dart`; (2)
  `comment_references` on a doc comment in `tool_window.dart` that
  bracket-referenced `[CompactToolHost]`, a type not imported into
  that file — reworded to a plain (non-linked) name so the doc comment
  no longer promises a resolvable reference.
- Tagged `architectural`: file-scope check — `git status --short`
  after all edits shows exactly `packages/nesd/lib/main.dart` and
  `packages/nesd/lib/ui/emulator/emulator_screen.dart` modified, plus
  the two new files under `lib/ui/emulator/tools/`. None of the
  do-not-modify files (`emulator_tool.dart`,
  `emulator_tools_controller.dart`, `tool_widgets.dart`,
  `docked_tool_host.dart`, `compact_tool_host.dart`, any tool widget,
  `action_handler.dart`, the menu, settings, `RemoteNes`/isolate
  protocol) were touched.
- Tagged `macOS`: `fvm dart format .` clean (474 files, 0 changed on
  the final pass) and `fvm flutter analyze` (packages/nesd) back to
  the single pre-existing `analysis_options_deprecated_plugins`
  warning carried since Task 1 — nothing attributable to this task's
  four files.
- Tagged `macOS`: both required builds succeeded, back to back, with
  no Podfile/pbxproj/xcscheme rewrite this run (Task 3 already
  committed the recurring rewrite, so this task's builds landed on an
  already-upgraded project). `fvm flutter build macos --debug --flavor
  dev` (windowing off): 34.9s wall clock (9.29s user, 2.56s system) —
  `✓ Built build/macos/Build/Products/Debug-dev/NESd.app`.
  `FLUTTER_WINDOWING=true fvm flutter build macos --debug --flavor
  dev` (windowing on): 30.3s wall clock (9.83s user, 2.46s system) —
  same success output. `git status --short` after both builds still
  shows only this task's four files changed.
- Pending user run: open all five tools as windows, native close
  round-trip, GPU path with tools open (plan Task 4 step 6).

### 2026-08-09 — First interactive run (macOS, user at the keyboard)

- Tagged `macOS`: with no `--flavor`, `fvm flutter run -d macos` dies
  with `Error: Unable to find expected configuration in Xcode project.`
  from `build_macos.dart:164` — the tool wants a configuration named
  `Debug`, and this project only has `Debug-dev`/`Debug-prod`. Same
  pre-existing flavor gate Task 2 found for `flutter build`; the error
  text never mentions flavors. Run recipe for this branch is therefore
  `FLUTTER_WINDOWING=true fvm flutter run -d macos --flavor dev`.
- Tagged `architectural`: Flutter master enables Swift Package Manager
  by default; `flutter run` printed `Adding Swift Package Manager
  integration...` and warned that `gamepads_darwin`, `nesd_audio` and
  `nesd_texture` do not support SPM (staying on CocoaPods). The step
  rewrote `Runner.xcscheme` (recurring toolchain effect, committed
  here per the Task 3 precedent). "This will become an error in a
  future version of Flutter" — #244 should track SPM adoption for the
  two nesd plugins and the gamepads fork.
- Tagged `macOS`: FINDING — with the runner untouched on this point,
  all six windows (main + five tools) opened as native *tabs* of one
  window: macOS automatic window tabbing applies to the windowing
  API's NSWindows, and the framework does not opt out. Observed with
  "Prefer tabs when opening documents" presumably set on this machine;
  tab titles matched the tool titles, so per-window titles work.
  Runner-level fix applied: `NSWindow.allowsAutomaticWindowTabbing =
  false` in `applicationDidFinishLaunching`. Every macOS consumer of
  the windowing API will need this (or per-window `tabbingMode`) until
  the framework handles it; filed for the findings report.
- Tagged `macOS`: session restore observed working — the persisted
  `openTools` set reopened all five tools at app launch, before any
  menu interaction. (Plan Task 6 step 5.3 answered early.)

### 2026-08-09 — Interactive session, user observations (macOS)

- Tagged `macOS`: GPU display path VERDICT — rendering works. The
  `nesd_texture` Texture path survived engine-level plugin
  registration unchanged; the fix-don't-fall-back contingency never
  triggered. (Plan Task 3 step 5, the experiment's gating risk.)
- Tagged `macOS`: in the tabbed configuration, tabs can be dragged out
  of the tab bar to become separate windows — native tab tear-out
  works on the windowing API's NSWindows.
- Tagged `architectural`: APU Debug opens completely black while the
  game is paused (in-game menu open) and starts painting when the game
  resumes. New-visibility artifact, not a regression: the panel draws
  from per-frame data, and a windowed tool is visible during pause — a
  state the docked host never exposed (tools lived behind the menu
  route). Any windowed host inherits this for frame-fed tools.
- Tagged `macOS`: menu switch <-> native window round-trip "works
  perfectly" (user's words): native close flips the Debug Tools
  switch; re-toggle reopens the window. The
  EmulatorToolsController seam holds under a real window host.
- Tagged `macOS`: closing the main window quits NESd — designed
  behavior (MainWindowDelegate.onWindowDestroyed -> exit(0)); tool
  windows do not keep the process alive.
- Tagged `macOS`: execution log at full speed kills performance, and
  its window only repaints once recording is disabled again. User
  suspects this predates windowing; needs the docked control case
  (536d4ade or stable main) for comparison before the report calls it
  a windowing cost. (Plan Task 6 step 4, partially answered.)
- Tagged `architectural`: keyboard bindings — including the tool
  toggles — register only while the MAIN window has focus. Confirms
  the registry spec's Amendment 3 exactly: KeyboardInputHandler hangs
  off EmulatorWidget's Focus node, which lives in the main window's
  tree. Gamepad path untested so far. #244's biggest scope item.
- User's overall verdict after the session: "this feels production
  ready."

### 2026-08-09 — Interactive session 3, user observations (macOS)

- Tagged `macOS`: after the tabbing opt-out (883125b7), tools open as
  separate windows directly. The fix works.
- Tagged `macOS`: debugger from its own window "works perfectly" —
  pause, stepping, breakpoint add/remove dialogs, address dialog, all
  against the running emulator. The per-window MaterialApp/Navigator
  design carries the dialogs. (Q4 answered: works.)
- Tagged `macOS`: hot reload with tool windows open works perfectly.
- Tagged `architectural`: execution-log performance collapse
  reproduced in DOCKED mode too — it is pre-existing, NOT a windowing
  cost. The windowed observation stands (window repaints only once
  recording stops) but the report must not attribute the slowdown to
  multi-view rasterization. (Q5 resolved for the log's part.)
- Tagged `macOS`: STOCK RUNNER VERDICT (536d4ade + windowing flag) —
  hard crash at startup:
  `NSInternalInconsistencyException: 'Multiview can only be enabled
  before adding any view controllers.'`, thrown from
  `-[FlutterEngine enableMultiView]` via
  `InternalFlutter_WindowController_CreateRegularWindow` when Dart
  constructs the first WindowController. The stock runner's
  MainFlutterWindow attaches a FlutterViewController before Dart runs,
  which forecloses multi-view. Conclusion for #244: on macOS the
  engine-owned runner is a hard prerequisite for the windowing API,
  not a cleanup. (Q2 answered definitively; plan Task 2 step 5's
  "crash" arm.)
- Tagged `macOS`: incidental, same run — master defaults to Impeller
  (`Using the Impeller rendering backend (MetalSDF)`); the GPU path
  verdict above therefore also covers nesd_texture-under-Impeller.
  Pre-existing ld warning: `eslz4-mac64.dylib` built for macOS 26.4 vs
  the 12.0 deployment target — unrelated to windowing.
- Still pending: gamepad bindings with a tool window focused (user
  testing shortly); Linux (Task 5).

### 2026-08-09 — Interactive session 4, gamepad (macOS)

- Tagged `architectural`: gamepad tool-toggles work regardless of
  window focus — the global-provider prediction confirmed. In-game
  gamepad controls likewise work without main-window focus. Keyboard
  remains main-window-only. (Q3 fully answered.)
- Tagged `macOS`: BUG observed — the first window opened via gamepad
  entered a rapid open-close loop; other tools toggled cleanly with
  the same tap pattern. Unexplained; note this branch predates the
  #251 gamepad-input migration (old gamepad stack).
- Tagged `architectural`: BUG observed — after a while, a rapid loop
  of `Bad state: Tried to read the state of an uninitialized
  provider` from EmulatorToolsController.isOpen via
  ActionHandler.handleAction (action_handler.dart:119); tool bindings
  then stayed dead while in-game bindings kept working. Structural
  suspect (from reading the merged prep, not yet proven):
  actionHandler captures the notifier once as a constructor dep
  (`ref.watch(...notifier)`), while the autoDispose controller's
  build() re-runs on every settings write — a stale-notifier recipe
  under Riverpod 3 lifecycle rules. If confirmed this is a bug in the
  MERGED #243 prep (PR #298), merely first exercised by the windowed
  host's global gamepad path; diagnosis dispatched, discriminator
  (docked-mode repro) pending.

### 2026-08-09 — Gamepad bug diagnosis (from source; full report in
### .superpowers/sdd/.../gamepad-bug-diagnosis.md on this branch)

- Tagged `architectural`: FLAPPING EXPLAINED (established) —
  GamepadInputHandler hold-to-repeat: 500 ms delay, then
  Timer.periodic re-emits active actions at 10 Hz with value 1.0
  (gamepad_input_handler.dart:186-215); ActionHandler's ToggleTool
  branch is level-triggered, no edge detection
  (action_handler.dart:117-123). Held press flaps at ~10 Hz; a tap is
  fine. Pre-existing on main; fix (edge-trigger ToggleTool or exclude
  one-shots from repeat) belongs in the #251 gamepad migration.
- Tagged `architectural`: the stale-notifier suspicion recorded above
  was WRONG — riverpod 3.1.0 does not recreate notifiers on rebuild
  (notifier_provider.dart:543), and a disposed element throws
  UnmountedRefException, not this error. Actual steady state: once
  one EmulatorToolsController.build() throws, riverpod's debug-mode
  readSelf (element.dart:463-486) reports "uninitialized" on every
  later read, permanently — tool bindings die, everything else runs.

### 2026-08-09 — Error-loop trigger identified (user scrollback +
### docked discriminator)

- Tagged `macOS`: user confirmed the error loop does NOT occur in
  docked mode — windowing involvement proven empirically.
- Tagged `macOS`: first exception in the scrollback names the
  trigger: `'schedulerPhase == SchedulerPhase.idle' is not true` in
  SchedulerBinding.handleBeginFrame, reached from
  _MacOSPlatformInterface.destroyWindow <- WindowController.destroy
  <- WindowedToolHost._close <- sync <- ref.listen callback <-
  riverpod flush inside _UncontrolledProviderScopeState.build —
  i.e. Flutter's macOS destroyWindow SYNCHRONOUSLY pumps
  _beginFrame, and our listener ran during the build phase, so the
  frame pipeline re-entered mid-frame. Framework sharp edge worth an
  upstream flutter/flutter issue.
- Tagged `macOS`: the re-entrant frame then makes the provider
  rebuild twice in one frame: `Bad state: Tried to rebuild
  emulatorToolsControllerProvider multiple times in the same frame`
  (ProviderScheduler.debugNotifyDidBuild) — THE exception that
  poisons the element (see diagnosis above). Full chain: 10 Hz
  repeat storm (main bug) x destroy-during-build (host) x
  destroyWindow frame pump (framework) x riverpod debug poisoning.
- Tagged `architectural`: CONSEQUENCE FOR #244 — a windowed host
  must not run window create/destroy synchronously from provider
  notifications; lifecycle work must be deferred to scheduler-idle.
  Mitigation applied to WindowedToolHost on this branch (coalesced
  idle-scheduled sync); with it, a held toggle should still flap
  (main-side repeat bug, until #251) but no longer corrupt the
  scheduler or kill the bindings.

### 2026-08-09 — Linux session (user)

- Tagged `Linux`: tool windows "work well" on the COMPLETELY STOCK
  GTK runner — no runner changes were applied at all (the planned
  thread-policy edit was never needed; plan Task 5's question "what
  does the Linux runner need" answers: nothing observable). macOS
  needed an engine-owned runner rewrite; Linux needed zero lines.
- Tagged `Linux`: gamepad hold-to-repeat flapping reproduces (same
  main-side bug; the e148384d mitigation defers lifecycle, it does
  not stop the storm — #251 owns that fix). No Dart-side scheduler
  assertions and no provider poisoning observed on Linux, consistent
  with the mitigation working.
- Tagged `Linux`: during the flap storm the console repeats
  `GLib-GObject-CRITICAL: invalid (NULL) pointer instance` +
  `g_signal_connect_object: assertion 'G_TYPE_CHECK_INSTANCE
  (instance)' failed`, one pair per ~200 ms — i.e. one per
  open/close cycle at the storm's 5 windows/sec. Flutter's Linux
  embedder connects a signal on a NULL GObject during rapid window
  create/destroy. Non-fatal (app keeps running). Linux sibling of
  the macOS destroyWindow frame pump; upstream-issue-worthy.
- Tagged `Linux`: CORRECTION to "nothing observable" above, from a
  follow-up user report — the stock runner leaves an additional,
  completely BLACK window open: its own GtkWindow hosting the
  implicit FlView, unused once Dart creates the real windows. Linux
  therefore mirrors macOS in kind, smaller in degree: the windowing
  path works without runner surgery, but shipping needs the
  runner-created window suppressed. Note for #244: fl_register_plugins
  currently hangs off that FlView (my_application.cc), so removing
  the window is not a pure deletion — the plugin registration path
  must move, the same problem the macOS rewrite solved with an
  engine-owned delegate.

### 2026-08-09 — Final measurement gaps (user)

- Tagged `macOS`: post-fix hold test — with e148384d, a held gamepad
  toggle still flaps (main-side repeat bug, #251's to fix) but
  produces NO scheduler assertions and NO provider poisoning;
  bindings survive. The idle-deferred lifecycle mitigation is
  verified on macOS as well as Linux.
- Tagged `Linux`: GPU display path VERDICT — a loaded ROM renders on
  Linux too. nesd_texture's Linux implementation works under the
  windowing path unchanged, on the stock runner.

### 2026-08-09 — Correction: flapping behavior at branch head (user)

- Tagged `Linux`: CORRECTION to the Linux session above — at the
  current branch head (with e148384d), a held gamepad toggle does
  NOT visibly flap on Linux. The earlier "flapping is present there"
  observation most plausibly ran a pre-mitigation checkout (the
  branch was pushed before e148384d; exact Linux checkout not
  recorded — lesson: note the commit in every session entry).
  Plausible mechanism for the platform difference: the coalesced
  idle-deferred sync lets consecutive open/close state flips cancel
  before any window operation happens; Linux's event-loop timing
  coalesces more of the 10 Hz storm than macOS's does.
- Tagged `macOS`: at the same head, macOS still flaps visibly under
  a held toggle — its loop keeps pace with the repeat storm. On BOTH
  platforms there are no errors and window input handling stays
  intact. The remaining flap is purely the main-side hold-to-repeat
  bug (#251's fix); the windowing side is stable under it.
