# Input Subsystem — Design Spec

**Date:** 2026-06-29
**Sub-project:** #2 of 5 (UX/aesthetic upgrade roadmap)
**Status:** Approved — ready for implementation plan

---

## Context

`ou_estimator` is a Flutter Ornstein–Uhlenbeck parameter estimator. Sub-project
#1 (design system + adaptive shell) is merged: the estimation screen is now
responsive (two-pane master/detail at ≥840px) with a dedicated input pane that
was deliberately left room to grow.

Current input is a single multiline `TextField` parsed by `TextInputParser`,
which splits on `[,\s]+` and throws `FormatException` on the first bad token.
Compute errors surface only after pressing Compute.

Key finding from code review: **`OUEstimator.estimate(List<double> series,
{double dt = 1.0})` already accepts and applies `dt`** — `theta = -ln(b)/dt`,
`sigma` and `halfLife` derive from `theta`. So feeding Δt into the math is pure
UI/controller wiring; the domain estimator is **not** modified.

## Goal & Scope

Upgrade data entry with four capabilities:
1. Smart paste-parsing (newline-first, predictable; currency stripping; a
   thousands-separator warning instead of silent misparse).
2. File import (CSV/TXT) via `file_picker`, auto first-numeric-column with
   header skip.
3. A Δt control (numeric value + named unit) that flows into the existing
   estimator and labels θ / half-life with the chosen unit.
4. Inline validation: live parse summary that soft-gates the Compute button.

## Constraints (carry the project discipline)

- **Domain math untouched.** No edits to `lib/domain/use_cases/ou_estimator.dart`.
- **One new dependency:** `file_picker`. No others.
- Reuse the sub-project #1 design system (tokens, `GlassCard`, `SectionLabel`).
- All existing tests stay green except the parser tests, which are rewritten to
  the new `ParseResult` API (the parser's public contract changes by design).
- Gate: `flutter analyze` clean · `flutter test` green · `flutter build macos
  --debug` ✓.

## Locked Decisions

- **Δt:** value (`double`, default `1.0`) + named unit (default `steps`). Value
  feeds `estimate(series, dt: value)`; unit is the display label and drives the
  persisted `samplingIntervalSeconds`.
- **Parse rules:** newline-first, predictable. Newlines present → one value per
  line, take the first numeric column, skip a non-numeric header row. No
  newlines → split on commas/whitespace. Strip `$ € £` and spaces. Single-line
  grouping commas (`\d,\d{3}`) raise a non-blocking warning, not a misparse.
- **File import:** `file_picker`; read file text; reuse the parser; auto-skip a
  non-numeric header; take the first column that parses as numbers.
- **Validation:** live summary (count · min…max, or red error / amber warning);
  Compute disabled unless input parses and has ≥ 3 points.

---

## Architecture

### New & modified files

| File | Change |
|------|--------|
| `lib/data/services/text_input_parser.dart` | **Rewrite.** Replace throw-based `parse()` with a non-throwing structured `ParseResult parse(String raw)` shared by the compute path and live validation. |
| `lib/data/services/file_import_service.dart` | **Create.** Thin `file_picker` wrapper: `Future<String?> pickTextFile()` returns file contents (.csv/.txt) or `null` if cancelled. IO only. |
| `lib/domain/value/dt_unit.dart` | **Create.** `enum DtUnit` + label + seconds-per-unit factor. Pure Dart, no Flutter. (Domain *value*, not the estimator — estimator stays untouched.) |
| `lib/providers/providers.dart` | **Modify.** Add `fileImportServiceProvider`. (`textInputParserProvider` already exists; its type is unchanged — still `Provider<TextInputParser>`.) |
| `lib/ui/estimation/estimation_state.dart` | **Modify.** Add `final String unitLabel` (default `'steps'`) so results can label θ / half-life. |
| `lib/ui/estimation/estimation_controller.dart` | **Modify.** `compute(String raw, {required double dt, required DtUnit unit})`: parse via `ParseResult`; on `canCompute` call `estimate(series, dt: dt)`; persist real `samplingIntervalSeconds`; store `unit.label` in state. |
| `lib/ui/estimation/widgets/input_panel.dart` | **Create.** Extracts the input column from `estimation_screen.dart`: text field, Δt value field + unit dropdown, file-import button, live validation summary, Compute button (soft-gated). |
| `lib/ui/estimation/widgets/validation_summary.dart` | **Create.** Pure presentation of a `ParseResult`: count · min…max, or red error / amber warning line. |
| `lib/ui/estimation/estimation_screen.dart` | **Modify.** Replace its inline `_buildInput` body with `InputPanel`; pass dt + unit into the controller. Two-pane / single-column layout from #1 unchanged. |
| `lib/ui/estimation/widgets/metrics_panel.dart` | **Modify.** Use `result`'s unit label: θ unit → `per {unitLabel}`, half-life unit → `{unitLabel}` (replacing the hardcoded `'steps'`). |
| `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements` | **Modify.** Add `com.apple.security.files.user-selected.read-only` so `file_picker` can open files on macOS. |

### `ParseResult` contract

```dart
class ParseResult {
  const ParseResult({
    required this.values,
    this.error,
    this.warning,
  });

  final List<double> values;
  final String? error;     // blocks Compute (unparseable / no numbers)
  final String? warning;   // non-blocking (e.g. thousands-separator suspicion)

  int get count => values.length;
  double? get min => values.isEmpty ? null : values.reduce(math.min);
  double? get max => values.isEmpty ? null : values.reduce(math.max);
  bool get canCompute => error == null && values.length >= 3;
}
```

`parse('')` → `ParseResult(values: [], error: 'Enter a price series …')`.
A bad token → `error: '"abc" is not a valid number.'`, `values` holds what
parsed so the summary can still show context.

### `DtUnit`

```dart
enum DtUnit {
  steps(label: 'step', seconds: 1),        // unitless index; ≈1s for storage
  seconds(label: 'second', seconds: 1),
  minutes(label: 'minute', seconds: 60),
  hours(label: 'hour', seconds: 3600),
  days(label: 'day', seconds: 86400),
  weeks(label: 'week', seconds: 604800),
  months(label: 'month', seconds: 2592000),   // ≈30 days (documented approx)
  years(label: 'year', seconds: 31536000);     // ≈365 days (documented approx)

  const DtUnit({required this.label, required this.seconds});
  final String label;
  final int seconds;
}
```

The numeric Δt value (not the unit's seconds) is what enters
`estimate(series, dt: value)`. Persisted `samplingIntervalSeconds =
value * unit.seconds`.

## Data Flow

1. User types/pastes, or imports a file (`FileImportService.pickTextFile()` →
   text dropped into the field).
2. On every field change the screen runs `parser.parse(text)` → a live
   `ParseResult`.
3. `ValidationSummary` renders the result; Compute is enabled iff
   `result.canCompute`.
4. On Compute: `controller.compute(text, dt: dtValue, unit: dtUnit)` →
   parse → `estimate(series, dt: dtValue)` → state (with `unitLabel`) →
   `MetricsPanel` + `PriceChart`.

## Error Handling

- Parse error → red line in `ValidationSummary`; Compute disabled.
- Thousands-separator suspicion → amber warning; Compute still allowed.
- File cancelled → no-op. File unreadable/empty → red inline error. Parsed file
  text populates the field so the user sees exactly what loaded.
- Estimator exceptions (`InsufficientDataException`, `NonStationaryException`)
  → existing on-Compute error banner, unchanged.

## Component Boundaries

- `TextInputParser` — *what:* text → `ParseResult`. *Depends on:* nothing
  (pure Dart). Same parser serves live validation and compute.
- `FileImportService` — *what:* pick + read a text file. *Depends on:*
  `file_picker`. No parsing.
- `DtUnit` — *what:* unit label + seconds factor. *Depends on:* nothing.
- `ValidationSummary` — *what:* render a `ParseResult`. *Depends on:* design
  tokens. Stateless.
- `InputPanel` — *what:* the whole input column. *Depends on:* parser, file
  service, `DtUnit`, `ValidationSummary`, controller. Owns the text controller
  and dt/unit local state.

## Testing

- **Parser** (rewrite existing 5 tests to `ParseResult`): newline-first one
  value per line; first-numeric-column from multi-column rows; header-row skip;
  currency/space stripping; single-line comma/whitespace split; thousands
  warning on `1,000`; empty → error; bad token → error with partial values;
  `count`/`min`/`max`; `canCompute` false at <3, true at ≥3.
- **Δt scaling** (estimator test, no production change): `estimate(series,
  dt: 2)` yields `theta` ≈ half of `estimate(series, dt: 1)` and `halfLife` ≈
  double — proves the wiring target behaves.
- **DtUnit:** `samplingIntervalSeconds` factor maths (value × unit.seconds).
- **Widget:** Compute disabled on empty/bad/<3 input, enabled on valid; unit
  label flows to `MetricsPanel` (θ shows `per day` when unit = days).
- `file_picker` IO not unit-tested (thin wrapper kept minimal).

## New Dependency / Platform

- Add `file_picker` to `pubspec.yaml`.
- macOS: add `com.apple.security.files.user-selected.read-only` to both
  `DebugProfile.entitlements` and `Release.entitlements`.

## Out of Scope (later or dropped)

- Multi-column picker (auto first-column only).
- Drag-and-drop file loading.
- Per-point spreadsheet-style editing grid (we validate the text field live; we
  do not build a cell editor).
- History (#4), export (#5), MLE / fit diagnostics (#3).
