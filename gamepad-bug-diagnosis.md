# Gamepad toggle bug diagnosis — 2026-08-09

Scope: the two bugs from interactive session 4 (macOS, windowed):
(1) first window opened via gamepad flapped open/close rapidly;
(2) later, a permanent loop of `Bad state: Tried to read the state of
an uninitialized provider` from `EmulatorToolsController.isOpen` via
`ActionHandler.handleAction` (action_handler.dart:119), after which
tool bindings stayed dead while in-game bindings kept working.

Verdict up front: **both bugs live in code that is on `main` today**
(the merged #243 prep plus the long-standing gamepad repeat feature).
The windowed host is the messenger, not the cause.

---

## Bug 1 — the open/close flap: ESTABLISHED

**Mechanism: gamepad hold-to-repeat re-fires ToggleTool 10x/second.**

- `GamepadInputHandler._handleGamepadEvent` has proper edge detection
  for press/release (`_addActions` emits only actions not present in
  the previous state's action set) —
  `gamepad_input_handler.dart:67-96,141-166`. A held button does NOT
  re-emit through this path.
- But every over-threshold event also calls `_startRepeatDelay()`
  (`gamepad_input_handler.dart:186-193`): after **500 ms** of hold it
  starts `Timer.periodic(100 ms)` (`_startRepeat`,
  `gamepad_input_handler.dart:195-215`) which re-emits **every**
  currently-active bound action with `value: 1.0`, ten times per
  second, until release.
- `ActionHandler.handleAction` treats ToggleTool as level-triggered:
  `if (event.value > 0.5) { toolsController.toggle(tool); }`
  (`action_handler.dart:117-123`). No edge detection, no repeat
  filtering. Each 100 ms repeat tick = one full toggle.
- Observed behavior matches exactly: a press held ≥500 ms flaps the
  window at ~10 Hz ("very fast open-close loop"); a quick tap
  (<500 ms) toggles once ("other windows worked fine ... by a tap").
  Nothing distinguishes the "first" window except that it was the
  press the user held longest.

The repeat feature predates the prep (it exists for menu navigation);
`ToggleTool` (added by the merged #243 prep, PR #298) is the first
**one-shot** action reachable during gameplay, and it collides with
repeat. In-game actions are level-based (down/up pairs), so repeat is
harmless for them — that is why only tool toggles misbehave.

**Reachable on `main` in docked mode:** yes — same handler, same
repeat, same ToggleTool branch; gamepad events are route-global.
Holding a bound tool button for 2-3 s in the docked app should flap
the docked panel identically.

---

## Bug 2 — the permanent "uninitialized provider" loop

### ESTABLISHED (riverpod 3.1.0 source)

- **The notifier is NOT recreated on rebuild.**
  `$ClassProviderElement.create` instantiates the notifier through
  `classListenable.result ??= $Result.guard(() { ... provider.create()
  ... })` — the `??=` caches it for the element's lifetime
  (`riverpod-3.1.0/lib/src/core/provider/notifier_provider.dart:543-550`).
  So ActionHandler's constructor-held notifier does not go stale from
  ordinary rebuilds. (Q1a answered: same instance.)
- **A disposed element would throw a different error.**
  `AnyNotifier.state` first calls `ref._throwIfInvalidUsage()`, which
  throws `UnmountedRefException` when the ref is unmounted
  (`notifier_provider.dart:80-85`; `core/ref.dart:214-221`). The user
  did NOT get that error, so the element was alive. (Rules out the
  simple stale-notifier-after-autoDispose theory.)
- **The observed error is the debug-mode "never set state" branch.**
  `ProviderElement.readSelf()` returns the `Tried to read the state of
  an uninitialized provider` StateError when, in kDebugMode,
  `!_debugDidSetState` (`core/element.dart:463-486`).
  `_debugDidSetState` is reset to `false` at the start of every
  rebuild (`_performRebuild`, `element.dart:567`) and only set back to
  `true` when a build actually delivers state (`element.dart:444,678`).
- **One failed build makes it permanent.** If
  `EmulatorToolsController.build()` throws, the error is routed to
  `handleError` (`notifier_provider.dart:552-566`) and
  `_debugDidSetState` stays `false`. The element is no longer dirty,
  so subsequent `state` reads go `readSelf() → flush()` (no-op:
  `_mustRecomputeState` is false, `element.dart:628-639`) and hit the
  debug branch **every time**. That yields exactly the observed
  steady-state: every gamepad ToggleTool event (including 10 Hz
  repeats) throws one uninitialized-provider error inside the action
  stream's `Zone.runUnaryGuarded`, the subscription survives, tool
  bindings are dead forever, and in-game actions (which never touch
  `toolsController`) keep working. `actionHandlerProvider` never
  rebuilds because the stuck element never notifies again.

### HYPOTHESIS (what threw the one failed build)

The failed `build()` ran during the Bug-1 write storm: 10 toggles/sec
means 10 settings writes/sec, each rebuilding the tools element
(its `build()` watches `settingsControllerProvider.select((s) =>
s.openTools)`, and `Set` has identity `==`, so every write fires),
interleaved with WindowedToolHost's `ref.listen` callback registering
windows (→ `WindowRegistry.notifyListeners` → `WindowManager`
rebuild) and destroying `WindowController`s. Candidate throwers, in
order of plausibility:

1. Re-entrant use of `Ref` inside a lifecycle/selector — riverpod
   asserts `'Cannot use Ref or modify other providers inside
   life-cycles/selectors.'` (`core/ref.dart:214-218`) — plausible if a
   window `destroy()` or registry notification re-enters provider code
   synchronously during the storm.
2. A transient error from `settingsControllerProvider` mid-storm.

Confirming evidence would be the FIRST exception in the user's
scrollback, printed before the uninitialized-provider loop began — it
would name the real thrower. The loop's own stack (readSelf) is the
symptom, not the cause.

Note: the permanence is a **debug-mode** behavior
(`kDebugMode` + `debugAssertDidSetStateEnabled`). In a release build
the same failed build would instead rethrow the original error per
read. Either way the controller is unusable after the first failed
build until something re-invalidates it.

---

## Q3 candidates ruled out

- (a) Duplicate ActionHandlers double-toggling: not needed to explain
  the flap (repeat timer suffices) and no double-subscribe window was
  established — `actionHandlerProvider`'s `ref.onDispose(
  handler.dispose)` cancels the old stream subscription on rebuild
  (`action_handler.dart:53-77`). Not pursued further.
- (c) WindowedToolHost re-toggling: `windowed_tool_host.dart` never
  writes controller state from the open/close path; the close
  delegate only runs on a user close request. The host amplifies the
  storm (register/destroy per toggle) but does not originate toggles.

## Where the fixes belong

**On `main` (bug is in merged code, reachable docked):**
1. Make ToggleTool edge-triggered or repeat-immune: either track
   per-action pressed state in `ActionHandler` and toggle only on the
   0→1 transition, or tag one-shot actions so
   `GamepadInputHandler._startRepeat` skips them. (Also worth noting:
   the in-flight #251 gamepad migration rewrites this input path —
   the fix should land wherever that migration puts the repeat
   logic.)
2. Consider hardening `EmulatorToolsController` consumers against a
   failed build (the permanent-lockup shape), though fixing the
   repeat storm removes the observed trigger.

**Branch-side (optional mitigation only):** deferring
WindowedToolHost's `sync()` work to a post-frame callback would
shrink the re-entrancy surface during storms, but is not established
as the thrower.

## Minimal discriminating experiment (user, ~2 min)

At `536d4ade` (or any docked build, including current `main`),
WITHOUT the windowing flag: bind a tool toggle to a gamepad button,
then **hold the button for ~3 seconds**.
- Expected per this diagnosis: the docked panel flaps at ~10 Hz
  (confirms Bug 1 on main).
- Keep holding / repeat a few times: if the uninitialized-provider
  loop also appears, Bug 2 is fully main-side too (confirms the storm
  trigger needs no windowing); if it never appears docked, the
  windowed host's register/destroy re-entrancy is a required
  ingredient and the branch mitigation above becomes relevant.

## Confidence

- Bug 1 mechanism: HIGH (code-traced end to end; timing constants
  match the observed behavior).
- Bug 2 steady-state mechanism (why it loops forever and only kills
  tool bindings): HIGH (riverpod source, matches every observed
  symptom).
- Bug 2 initial trigger (which exception broke the first build):
  UNCONFIRMED — two named candidates; user scrollback or the docked
  repro would settle it.
- Fix location on `main`: HIGH for Bug 1; MEDIUM-HIGH for Bug 2.
