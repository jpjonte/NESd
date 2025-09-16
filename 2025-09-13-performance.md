# 2025‑09‑13 Performance Session Summary

This session established a repeatable performance benchmarking and plotting
workflow for NESd, validated it locally, and fixed a header parsing edge case
that blocked a few ROMs. The output is graphable across commits and modes.

## What Was Added

- Headless bench + runners (CLI):
  - `bin/perf/bench.dart` — runs a single ROM, prints one JSON result.
  - `bin/perf/run.dart` — repeats runs, writes median to CSV and all runs to
    JSONL under `bin/perf/results/`.
  - `bin/perf/suite.dart` — executes the curated suite from
    `bin/perf/suite.json`.
  - `bin/perf/plot.dart` — generates `bin/perf/results/plot.html` from CSV.
  - `bin/perf/suite.json` — curated ROMs for implemented mappers.
- Shell helpers (for convenience):
  - `bin/perf/run_bench.sh`
  - `bin/perf/run_suite.sh`
- Test‑based suite runner:
  - `bin/perf/bench_test.dart` — runs the suite in `flutter_test` so
    `dart:ui` is available and all app code loads cleanly.
- Results location:
  - All artifacts now live in `bin/perf/results/` (CSV, JSONL, plot HTML).

## Key Fixes

- `lib/nes/cartridge/cartridge_factory.dart`:
  - `_parseTvSystem` now maps unknown iNES values to NTSC instead of throwing.
    This unblocked ROMs with reserved/unknown TV system bits.

## What Was Verified

- Installed Flutter 3.35.3 via FVM and ran the suite locally.
- Generated results CSV/JSONL and produced `plot.html`.
- Confirmed the CLI and test runners both work; the test runner writes
  `mode=flutter_test` while the CLI uses `jit/profile/release` labels.

## How To Use

- Single ROM (median via CLI):
  - `dart run bin/perf/run.dart --rom <path> --frames 200 --warmup 50 --runs 9`
  - JSONL + CSV append to `bin/perf/results/`.
- Full suite:
  - `dart run bin/perf/suite.dart`
  - Configurable via `bin/perf/suite.json` (frames, warmup, runs, ROMs).
- Plot:
  - `dart run bin/perf/plot.dart`
  - Opens `bin/perf/results/plot.html`.
- Flutter test runner:
  - `fvm flutter test -t perf bin/perf/bench_test.dart`

## Notes On Multiple Points Per Build

- CSV is append‑only; repeated runs at the same commit/ROM/mode produce
  multiple points in the chart. The plot groups by `ROM • mode` and sorts by
  timestamp.

## Current Defaults

- Suite defaults are set to shorter cycles for speed:
  - `frames=120`, `warmup=30`, `runs=3`.
  - Adjust in `bin/perf/suite.json` for higher confidence medians.

## Next Steps

- CSV/Plot deduping
  - Collapse rows by `(commit, rom, mode)` in the plotter, keeping latest
    or computing a median of medians to show one point per build.

- Pure Dart mode for bench CLI
  - Decouple `bench.dart` from any code that pulls `dart:ui` (via
    `RomInfo`), so the CLI never needs the Flutter environment.

- Profile modes
  - Add `--mode profile` path that runs with VM profiling enabled and
    optionally captures DevTools CPU profile exports for hotspot analysis.

- Timeline instrumentation
  - Add `dart:developer` `TimelineTask` scopes in hot paths (PPU fetch,
    render, Bus reads, APU sampling). Summarize self‑time by tag per run.

- Memory/alloc metrics
  - Track simple allocation proxies (e.g., frame‑time variance, bytes
    allocated if available) and append to CSV for trend analysis.

- CI integration
  - Add a CI job to run the suite on one desktop target, upload
    `results.csv` and `plot.html` as artifacts. Gate merges on a
    performance budget or regression threshold (e.g., max +3% frame time).

- Suite coverage
  - Expand/curate ROMs per mapper to include heavier PPU/IRQ cases and keep
    a balanced mix of CPU‑bound vs PPU‑bound titles.

- Stability & reproducibility
  - Document power plan, CPU governor, and “close background apps” advice.
  - Pin the window/headless mode and disable vsync for consistent runs.

- Reporting
  - Add a small “delta vs previous” summary table in the plot HTML.
  - Add per‑platform/mode filters in the plot page.

- Defaults and configs
  - Provide `suite.quick.json` and `suite.full.json` presets for fast
    iteration vs. CI‑grade runs.

- Chart design
  - Switch to a lollipop chart to reduce visual clutter
