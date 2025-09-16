# Repository Guidelines

NESd is an open-source Nintendo Entertainment System (NES) emulator built with Flutter and Dart, and supports desktop (macOS, Windows, Linux) and Android platforms. 

## Project Structure & Module Organization
- App code in `lib/`: core emulator (`lib/nes/`), UI (`lib/ui/`), audio (`lib/audio/`), utilities (`lib/util/`), extensions/hooks.
- Tests in `test/` with platform config in `test/flutter_test_config.dart` and sample ROM tests under `test/test_roms/`.
- Assets in `assets/` (fonts, images). Platform folders: `macos/`, `linux/`, `windows/`, `android/`.
- CI and release scripts in `ci/`; docs and screenshots in `docs/`.

## Build, Test, and Development Commands
- Use FVM.
- Install Flutter (see `.fvmrc`). With FVM: `fvm flutter ...`.
- Fetch deps: `flutter pub get`.
- Run locally (examples): `flutter run -d macos`, `flutter run -d windows`, `flutter run -d linux`.
- Analyze/format: `dart format .` and `flutter analyze`.
- Tests: `flutter test` or with coverage: `flutter test --coverage && ci/0-test/extract_coverage.sh`.
- Desktop builds: `flutter build macos --release`, `flutter build windows --release`, `flutter build linux --release --target-platform=linux-x64`.
- Android APKs: `flutter build apk --release --flavor dev|prod`.
- Codegen (when editing Freezed/JSON files): `dart run build_runner build -d` (or `watch -d`).

## Coding Style & Naming Conventions
- Follow `analysis_options.yaml` (strict lint). Key points: 2-space indent, snake_case file names, prefer `final`/`const`, package imports (`package:nesd/...`).
- Keep lines ≤ 80 chars (rule enabled). Run `dart format` before committing.
- Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis.

The following rules go beyond what `dart format` enforces and should guide how you structure changes:

- Breathing room
    - Insert empty lines between code blocks that are not a tight logical unit.
    - Leave a blank line before and after `if`/`else`, `for`, `while`, and `switch` blocks.
    - Use blank lines to separate variable initialization groups from subsequent control flow.

- Early returns and guard clauses
    - Prefer early returns to reduce nesting instead of `else` after a `return`.
    - Keep conditional checks small and focused; separate multi-step logic with blank lines.

- Immutability first
    - Use `final` for local variables and fields by default.
    - Mark simple data holders with `@immutable` when appropriate and prefer generated serializers (`JsonSerializable`, Freezed) for value types.

- Constructors over static factories
    - Prefer `factory` constructors like `Record.fromCols(...)` instead of static methods, aligning with `prefer_constructors_over_static_methods`.
    - Put required named parameters first and mark constructors `const` when possible.

- Pattern matching and switch expressions
    - Use Dart 3 pattern matching and switch expressions for compact mappings and lookups (e.g., `switch` expressions and `case final x?` guards).

- Cascades for related operations
    - When making several calls on the same receiver (e.g., `StringBuffer`, `Canvas`, `Path`, or builder-like APIs), use cascades (`..`) instead of repeating the receiver.
    - Avoid single-cascade statements; only use cascades when they improve readability across multiple calls.

- Strings and long literals
    - Prefer single quotes for Dart strings; use double quotes inside generated HTML/SVG where appropriate.
    - For long, structured literals (e.g., SVG/HTML), use triple-quoted strings or `StringBuffer` with cascades to stay within 80 columns and improve readability.

- Small, focused helpers
    - Keep private helpers (`_name`-prefixed) near their call sites.
    - Favor short functions that do one thing well over large, deeply nested functions.

These conventions aim to keep code readable and scannable, making it easier to understand one small logical unit at a time.

## Verification
- After any code change, run `dart format .` and `dart analyze` on only the changed files and fix all reported issues.
- Performance changes can be benchmarked with the scripts found in `bin/perf/`.

## Testing Guidelines
- Use `flutter_test` and `mocktail`. Place tests in `test/` and name `*_test.dart`.
- Coverage artifacts can be generated via the command above; aim to keep or improve coverage.
- Tests load platform-specific LZ4 libs via `flutter_test_config.dart`; run on macOS/Linux/Windows (not web).

## Commit & Pull Request Guidelines
- Commits: short, imperative subject; reference issues (e.g., `#123 Fix input lag`).
- Ensure `dart format`, `flutter analyze`, and tests pass locally.
- Update `CHANGELOG.md` under “Unreleased” for user-facing changes.

## Security & Configuration Tips
- No secrets in code. Local builds don’t require CI keys. Use the Flutter version in `.fvmrc` to avoid drift.
