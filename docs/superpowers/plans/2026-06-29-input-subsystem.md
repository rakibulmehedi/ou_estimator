# Input Subsystem Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade data entry with smart paste-parsing, CSV/TXT file import, a Δt value+unit control that flows into the existing estimator, and live inline validation that soft-gates the Compute button.

**Architecture:** Replace the throw-based parser with a non-throwing `ParseResult` shared by live validation and the compute path. Add a thin `file_picker` service and a pure `DtUnit` value enum. Extract the input column into a stateful `InputPanel` that owns the series text, Δt value, and unit; the existing `OUEstimator.estimate(series, {dt})` already applies `dt`, so the domain math is untouched.

**Tech Stack:** Flutter (Material 3), Riverpod, `file_picker` (new). Reuses sub-project #1 design system (`tokens.dart`, `GlassCard`, `SectionLabel`).

## Global Constraints

- **Domain math untouched.** No edits to `lib/domain/use_cases/ou_estimator.dart`.
- **One new dependency only:** `file_picker`. No others.
- Reuse the #1 design system: `Spacing`/`Radii`/`Motion` from `lib/ui/core/tokens.dart`, `AppTheme` colors from `lib/ui/core/theme.dart`, `SectionLabel`.
- Parser contract changes by design: `TextInputParser.parse` returns `ParseResult` (no longer throws). The 5 existing parser tests are rewritten.
- Δt: numeric value (default `1.0`) + `DtUnit` (default `DtUnit.steps`). The numeric value enters `estimate(series, dt: value)`; persisted `samplingIntervalSeconds = value * unit.secondsPerUnit`.
- Parse rules: newline-first. Newlines → one value per line, first numeric column, skip a non-numeric header. No newlines → split on `[,\s]+`. Strip `$ € £` and spaces. Single-line `\d,\d{3}` → non-blocking warning.
- Validation: Compute enabled iff `result.canCompute` (no error AND ≥ 3 values) AND Δt value > 0.
- Naming reconciliation: `DtUnit.steps.label == 'step'`; `EstimationState.unitLabel` default `'step'`; `MetricsPanel` renders half-life unit as `'${unitLabel}s'` (→ `'steps'`) and θ unit as `'per $unitLabel'` (→ `'per step'`).
- Test runner: `flutter test` (use `fvm flutter test` if the toolchain is fvm-managed). Gate: `flutter analyze` clean · `flutter test` green · `flutter build macos --debug` ✓.
- Branch work off `main` on a feature branch before Task 1.

---

### Task 0: Feature branch

- [ ] **Step 1: Branch from main**

```bash
git checkout main
git pull --ff-only 2>/dev/null || true
git checkout -b feature/input-subsystem
```
Expected: on a clean `feature/input-subsystem` branch.

---

### Task 1: `DtUnit` value enum

**Files:**
- Create: `lib/domain/value/dt_unit.dart`
- Test: `test/dt_unit_test.dart`

**Interfaces:**
- Produces: `enum DtUnit { steps, seconds, minutes, hours, days, weeks, months, years }` with `final String label;` and `final int secondsPerUnit;` on each. (Field is `secondsPerUnit`, NOT `seconds` — a `seconds` instance field collides with the `DtUnit.seconds` enum value in Dart enhanced enums.)

- [ ] **Step 1: Write the failing test**

`test/dt_unit_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/value/dt_unit.dart';

void main() {
  test('labels are singular', () {
    expect(DtUnit.steps.label, 'step');
    expect(DtUnit.days.label, 'day');
    expect(DtUnit.years.label, 'year');
  });

  test('seconds factors are correct', () {
    expect(DtUnit.steps.secondsPerUnit, 1);
    expect(DtUnit.seconds.secondsPerUnit, 1);
    expect(DtUnit.minutes.secondsPerUnit, 60);
    expect(DtUnit.hours.secondsPerUnit, 3600);
    expect(DtUnit.days.secondsPerUnit, 86400);
    expect(DtUnit.weeks.secondsPerUnit, 604800);
    expect(DtUnit.months.secondsPerUnit, 2592000); // 30 days (approx)
    expect(DtUnit.years.secondsPerUnit, 31536000); // 365 days (approx)
  });

  test('all eight units exist', () {
    expect(DtUnit.values.length, 8);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dt_unit_test.dart`
Expected: FAIL — `dt_unit.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/domain/value/dt_unit.dart`:
```dart
/// Sampling interval unit for a price series. The numeric Δt value (not the
/// unit's [secondsPerUnit]) feeds `OUEstimator.estimate(series, dt: value)`;
/// [secondsPerUnit] converts the value to the persisted
/// `samplingIntervalSeconds`. [label] is singular and used to annotate θ
/// ("per <label>") and half-life ("<label>s").
///
/// The field is `secondsPerUnit` rather than `seconds`: a `seconds` instance
/// field would collide with the `DtUnit.seconds` enum value.
///
/// `months` and `years` use calendar approximations (30 / 365 days).
enum DtUnit {
  steps(label: 'step', secondsPerUnit: 1),
  seconds(label: 'second', secondsPerUnit: 1),
  minutes(label: 'minute', secondsPerUnit: 60),
  hours(label: 'hour', secondsPerUnit: 3600),
  days(label: 'day', secondsPerUnit: 86400),
  weeks(label: 'week', secondsPerUnit: 604800),
  months(label: 'month', secondsPerUnit: 2592000),
  years(label: 'year', secondsPerUnit: 31536000);

  const DtUnit({required this.label, required this.secondsPerUnit});

  final String label;
  final int secondsPerUnit;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/dt_unit_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/value/dt_unit.dart test/dt_unit_test.dart
git commit -m "feat: add DtUnit value enum"
```

---

### Task 2: `ParseResult` + parser rewrite

**Files:**
- Modify (full rewrite): `lib/data/services/text_input_parser.dart`
- Modify (full rewrite): `test/text_input_parser_test.dart`

**Interfaces:**
- Produces:
  - `class ParseResult { const ParseResult({required List<double> values, String? error, String? warning}); final List<double> values; final String? error; final String? warning; int get count; double? get min; double? get max; bool get canCompute; }`
  - `class TextInputParser { const TextInputParser(); ParseResult parse(String raw); }`

- [ ] **Step 1: Write the failing test (rewrite the file)**

Replace the entire contents of `test/text_input_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/services/text_input_parser.dart';

void main() {
  const parser = TextInputParser();

  test('newline input: one value per line', () {
    final r = parser.parse('1\n2.5\n3');
    expect(r.values, [1.0, 2.5, 3.0]);
    expect(r.error, isNull);
  });

  test('newline input: takes first numeric column, skips header row', () {
    final r = parser.parse('price,volume\n10,500\n11,600\n12,700');
    expect(r.values, [10.0, 11.0, 12.0]);
    expect(r.error, isNull);
  });

  test('strips currency symbols and spaces', () {
    final r = parser.parse(r'$10, $11, £12');
    expect(r.values, [10.0, 11.0, 12.0]);
  });

  test('single line: splits on commas and whitespace', () {
    final r = parser.parse('1, 2 3\t4');
    expect(r.values, [1.0, 2.0, 3.0, 4.0]);
    expect(r.warning, isNull);
  });

  test('single-line thousands grouping raises a non-blocking warning', () {
    final r = parser.parse('1,000 2,000');
    expect(r.warning, isNotNull);
  });

  test('empty input: error, not throw', () {
    final r = parser.parse('   ');
    expect(r.values, isEmpty);
    expect(r.error, isNotNull);
    expect(r.canCompute, isFalse);
  });

  test('bad token: error with partial values', () {
    final r = parser.parse('1, x, 3');
    expect(r.error, isNotNull);
    expect(r.values, [1.0]); // parsed before the bad token
  });

  test('count, min, max', () {
    final r = parser.parse('3\n1\n2');
    expect(r.count, 3);
    expect(r.min, 1.0);
    expect(r.max, 3.0);
  });

  test('canCompute gates on >= 3 valid points', () {
    expect(parser.parse('1\n2').canCompute, isFalse);
    expect(parser.parse('1\n2\n3').canCompute, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/text_input_parser_test.dart`
Expected: FAIL — `ParseResult` undefined / `parse` returns `List<double>`.

- [ ] **Step 3: Write the implementation (rewrite the file)**

Replace the entire contents of `lib/data/services/text_input_parser.dart`:
```dart
import 'dart:math' as math;

/// Structured outcome of parsing a price-series text input. Non-throwing so the
/// same call serves both the Compute path and live inline validation.
class ParseResult {
  const ParseResult({required this.values, this.error, this.warning});

  /// Values parsed so far. On [error] this holds whatever parsed before the
  /// failure, so callers can still show context.
  final List<double> values;

  /// Blocks Compute (unparseable token / no numbers / empty).
  final String? error;

  /// Non-blocking advisory (e.g. a suspected thousands separator).
  final String? warning;

  int get count => values.length;
  double? get min => values.isEmpty ? null : values.reduce(math.min);
  double? get max => values.isEmpty ? null : values.reduce(math.max);

  /// Estimation needs at least 3 observations and no hard error.
  bool get canCompute => error == null && values.length >= 3;
}

/// Parses a price series from free-form text into a [ParseResult].
///
/// Newline-first and predictable: if the input contains newlines, each line is
/// one observation and only the first numeric column is read (a non-numeric
/// header row is skipped). Without newlines, tokens are split on commas and
/// whitespace. Currency symbols (`$ € £`) and spaces are stripped. A
/// single-line thousands grouping (e.g. `1,000`) raises a non-blocking warning
/// rather than being silently misparsed.
class TextInputParser {
  const TextInputParser();

  static final RegExp _delimiter = RegExp(r'[,\s]+');
  static final RegExp _currency = RegExp(r'[\$€£\s]');
  static final RegExp _thousands = RegExp(r'\d,\d{3}');

  ParseResult parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const ParseResult(
        values: [],
        error: 'Enter a price series to begin.',
      );
    }

    if (text.contains('\n')) {
      return _parseLines(text);
    }
    return _parseSingleLine(text);
  }

  ParseResult _parseLines(String text) {
    final values = <double>[];
    String? error;
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      // First column = first delimiter-separated token on the line.
      final firstToken = line.split(_delimiter).first;
      final v = double.tryParse(_clean(firstToken));
      if (v == null) {
        // Allow a single leading non-numeric header row to be skipped.
        if (values.isEmpty && i == 0) continue;
        error = '"$firstToken" is not a valid number.';
        break;
      }
      values.add(v);
    }
    if (values.isEmpty && error == null) {
      error = 'No numbers found.';
    }
    return ParseResult(values: values, error: error);
  }

  ParseResult _parseSingleLine(String text) {
    final warning = _thousands.hasMatch(text)
        ? 'Looks like a thousands separator (e.g. 1,000). '
            'Put one value per line to be safe.'
        : null;

    final values = <double>[];
    final tokens = text.split(_delimiter).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      final v = double.tryParse(_clean(t));
      if (v == null) {
        return ParseResult(
          values: values,
          error: '"$t" is not a valid number.',
          warning: warning,
        );
      }
      values.add(v);
    }
    if (values.isEmpty) {
      return const ParseResult(values: [], error: 'No numbers found.');
    }
    return ParseResult(values: values, warning: warning);
  }

  String _clean(String token) => token.replaceAll(_currency, '');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/text_input_parser_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Verify nothing else broke yet**

Run: `flutter test`
Expected: The controller still compiles? It calls `parser.parse(raw)` expecting a `List<double>`. This WILL fail to compile until Task 4. That is expected — note it and proceed. (If you prefer a green suite at every boundary, you may run only the two files touched here in Step 4 and defer the full run; the controller is fixed in Task 4.)

- [ ] **Step 6: Commit**

```bash
git add lib/data/services/text_input_parser.dart test/text_input_parser_test.dart
git commit -m "feat: rewrite parser to non-throwing ParseResult"
```

---

### Task 3: `EstimationState.unitLabel` + Δt-scaling estimator test

**Files:**
- Modify: `lib/ui/estimation/estimation_state.dart`
- Test: `test/ou_estimator_test.dart` (add one test; do not change existing tests)
- Test: `test/estimation_state_test.dart` (create)

**Interfaces:**
- Consumes: nothing new.
- Produces: `EstimationState` gains `final String unitLabel;` (default `'step'`) and `copyWith({..., String? unitLabel})`.

- [ ] **Step 1: Write the failing state test**

`test/estimation_state_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/ui/estimation/estimation_state.dart';

void main() {
  test('unitLabel defaults to "step"', () {
    expect(const EstimationState().unitLabel, 'step');
  });

  test('copyWith updates unitLabel and preserves it when omitted', () {
    final a = const EstimationState().copyWith(unitLabel: 'day');
    expect(a.unitLabel, 'day');
    final b = a.copyWith(loading: true);
    expect(b.unitLabel, 'day');
  });
}
```

- [ ] **Step 2: Add the Δt-scaling estimator test**

Append to `test/ou_estimator_test.dart` inside its `main()` (this proves the wiring target; no production change to the estimator):
```dart
  test('dt scales theta inversely and half-life proportionally', () {
    final estimator = OUEstimator();
    const series = [
      10.0, 9.4, 9.8, 10.3, 9.9, 10.1, 9.7, 10.0, 10.2, 9.85, 10.05, 9.95
    ];
    final r1 = estimator.estimate(series, dt: 1.0);
    final r2 = estimator.estimate(series, dt: 2.0);
    expect(r2.theta, closeTo(r1.theta / 2, 1e-9));
    expect(r2.halfLife, closeTo(r1.halfLife * 2, 1e-9));
  });
```
If `test/ou_estimator_test.dart` does not already import the estimator, it does (existing tests use `OUEstimator`); reuse that import.

- [ ] **Step 3: Run tests to verify failure**

Run: `flutter test test/estimation_state_test.dart`
Expected: FAIL — `unitLabel` getter not defined.
(The estimator test in Step 2 should already PASS, since `estimate` accepts `dt` today — that is intentional; it locks the behavior the controller will rely on.)

- [ ] **Step 4: Implement the state change**

In `lib/ui/estimation/estimation_state.dart`, add the field, constructor param, and `copyWith` handling. The full updated file:
```dart
import '../../domain/use_cases/ou_estimator.dart';

/// Immutable snapshot of the estimation screen.
class EstimationState {
  const EstimationState({
    this.series = const [],
    this.result,
    this.error,
    this.loading = false,
    this.unitLabel = 'step',
  });

  final List<double> series;
  final OUResult? result;
  final String? error;
  final bool loading;

  /// Singular unit label for the active Δt (e.g. 'day'); annotates θ / half-life.
  final String unitLabel;

  bool get hasResult => result != null;

  EstimationState copyWith({
    List<double>? series,
    OUResult? result,
    String? error,
    bool? loading,
    String? unitLabel,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return EstimationState(
      series: series ?? this.series,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
      unitLabel: unitLabel ?? this.unitLabel,
    );
  }
}
```

- [ ] **Step 5: Run the state test to verify it passes**

Run: `flutter test test/estimation_state_test.dart test/ou_estimator_test.dart`
Expected: PASS (state: 2 tests; estimator: existing + the new scaling test).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/estimation/estimation_state.dart test/estimation_state_test.dart test/ou_estimator_test.dart
git commit -m "feat: add EstimationState.unitLabel and dt-scaling estimator test"
```

---

### Task 4: Controller — `compute(raw, {dt, unit})`

**Files:**
- Modify: `lib/ui/estimation/estimation_controller.dart`
- Modify (one call site, keep it compiling): `lib/ui/estimation/estimation_screen.dart:112`
- Test: `test/estimation_controller_test.dart` (create)

**Interfaces:**
- Consumes: `ParseResult` (Task 2), `DtUnit` (Task 1), `EstimationState.unitLabel` (Task 3).
- Produces: `Future<void> compute(String raw, {double dt = 1.0, DtUnit unit = DtUnit.steps})`.

- [ ] **Step 1: Write the failing controller test**

`test/estimation_controller_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/value/dt_unit.dart';
import 'package:ou_estimator/providers/providers.dart';

void main() {
  test('compute parses, estimates, and records the unit label', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    // Mean-reverting series (estimated AR(1) b ≈ 0.51, in (0,1)); the old
    // zig-zag seed had b < 0 and the estimator (correctly) throws on it.
    await notifier.compute(
      '11.2\n10.51\n10.37\n10.32\n10.02\n10.19\n9.91\n9.89\n9.74\n9.67\n9.84\n10.1',
      dt: 1.0,
      unit: DtUnit.days,
    );

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isTrue);
    expect(state.unitLabel, 'day');
    expect(state.error, isNull);
  });

  test('compute surfaces a parse error and produces no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    await notifier.compute('not numbers');

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isFalse);
    expect(state.error, isNotNull);
  });
}
```
(Persistence reads `estimationRepositoryProvider`, which depends on the un-overridden `isarProvider` and throws; the controller swallows that in a best-effort `try/catch`, so these tests need no Isar.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/estimation_controller_test.dart`
Expected: FAIL — `compute` signature / `ParseResult` mismatch (compile error).

- [ ] **Step 3: Rewrite the controller**

Replace the entire contents of `lib/ui/estimation/estimation_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/dt_unit.dart';
import '../../providers/providers.dart';
import 'estimation_state.dart';

/// Drives the estimation screen: parse → estimate → display → persist.
///
/// The compute path (parse + OLS) is synchronous and fast, so a plain
/// [Notifier] with a `loading` flag is cleaner than an `AsyncNotifier`.
/// Persistence runs best-effort afterwards.
class EstimationController extends Notifier<EstimationState> {
  @override
  EstimationState build() => const EstimationState();

  Future<void> compute(
    String raw, {
    double dt = 1.0,
    DtUnit unit = DtUnit.steps,
  }) async {
    final parser = ref.read(textInputParserProvider);
    final estimator = ref.read(ouEstimatorProvider);

    state = state.copyWith(loading: true, clearError: true);

    final parsed = parser.parse(raw);
    if (parsed.error != null) {
      state = state.copyWith(
        loading: false,
        error: parsed.error,
        clearResult: true,
      );
      return;
    }

    final series = parsed.values;
    final OUResult result;
    try {
      result = estimator.estimate(series, dt: dt);
    } on InsufficientDataException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
        clearResult: true,
      );
      return;
    } on NonStationaryException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
        clearResult: true,
      );
      return;
    }

    state = state.copyWith(
      series: series,
      result: result,
      unitLabel: unit.label,
      loading: false,
      clearError: true,
    );

    // Persist best-effort — a storage failure must not hide a valid result.
    try {
      final repo = ref.read(estimationRepositoryProvider);
      await repo.save(
        name: 'session-${DateTime.now().millisecondsSinceEpoch}',
        series: series,
        samplingIntervalSeconds: dt * unit.secondsPerUnit,
        result: result,
      );
    } catch (_) {
      // Out of scope for UI feedback here.
    }
  }

  void clear() => state = const EstimationState();
}
```

- [ ] **Step 4: Keep the existing call site compiling**

The screen still calls the old form at `lib/ui/estimation/estimation_screen.dart` inside `_buildInput`. It compiles as-is because `dt`/`unit` are optional — no edit needed yet. (Confirm by reading line ~112: `() => notifier.compute(_controller.text)` remains valid.) The real wiring happens in Task 8.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/estimation_controller_test.dart`
Expected: PASS (2 tests).
Then run the full suite to confirm the app compiles again after the Task 2 parser change:
Run: `flutter test`
Expected: all green (parser, dt_unit, state, estimator, controller, plus the #1 UI tests).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/estimation/estimation_controller.dart test/estimation_controller_test.dart
git commit -m "feat: compute accepts dt and DtUnit, records unit label"
```

---

### Task 5: `FileImportService` + provider + `file_picker` dep + macOS entitlements

**Files:**
- Modify: `pubspec.yaml` (add `file_picker`)
- Create: `lib/data/services/file_import_service.dart`
- Modify: `lib/providers/providers.dart` (add provider)
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`

**Interfaces:**
- Produces:
  - `class FileImportService { const FileImportService(); Future<String?> pickTextFile(); }`
  - `final fileImportServiceProvider = Provider<FileImportService>((ref) => const FileImportService());`

> This task is config + a thin IO wrapper. There is no unit test (the wrapper just calls `file_picker` and decodes bytes); it is verified by `flutter analyze` and a macOS build that links the plugin.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:` (after `path_provider`), add:
```yaml
  # File import for CSV/TXT price series (sub-project #2).
  file_picker: ^8.1.0
```
Then run: `flutter pub get`
Expected: resolves and writes `pubspec.lock`.

- [ ] **Step 2: Create the service**

`lib/data/services/file_import_service.dart`:
```dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Thin wrapper over `file_picker` for importing a price series from a text
/// file. IO only — the returned text is parsed by [TextInputParser] elsewhere.
class FileImportService {
  const FileImportService();

  /// Opens a picker for `.csv` / `.txt` files and returns the file's text, or
  /// `null` if the user cancels or the file has no readable bytes.
  Future<String?> pickTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }
}
```

- [ ] **Step 3: Register the provider**

In `lib/providers/providers.dart`, add the import and the provider. Add near the other service imports:
```dart
import '../data/services/file_import_service.dart';
```
And after `textInputParserProvider`:
```dart
final fileImportServiceProvider =
    Provider<FileImportService>((ref) => const FileImportService());
```

- [ ] **Step 4: Add the macOS file-access entitlement**

In `macos/Runner/DebugProfile.entitlements`, inside `<dict>`, add:
```xml
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
```
In `macos/Runner/Release.entitlements`, inside `<dict>`, add the same two lines.

- [ ] **Step 5: Verify it compiles + links**

Run: `flutter analyze`
Expected: `No issues found!`
Run: `flutter build macos --debug`
Expected: `✓ Built …/ou_estimator.app` (pod install pulls the file_picker macOS plugin).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/services/file_import_service.dart lib/providers/providers.dart macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements
git commit -m "feat: add FileImportService with file_picker and macOS entitlement"
```

---

### Task 6: `ValidationSummary` widget

**Files:**
- Create: `lib/ui/estimation/widgets/validation_summary.dart`
- Test: `test/ui/validation_summary_test.dart`

**Interfaces:**
- Consumes: `ParseResult` (Task 2); `AppTheme`, `Spacing`.
- Produces: `class ValidationSummary extends StatelessWidget { const ValidationSummary({super.key, required ParseResult result}); }`

- [ ] **Step 1: Write the failing test**

`test/ui/validation_summary_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/data/services/text_input_parser.dart';
import 'package:ou_estimator/ui/estimation/widgets/validation_summary.dart';

Future<void> _pump(WidgetTester tester, ParseResult result) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ValidationSummary(result: result))),
  );
}

void main() {
  testWidgets('error result shows the error message', (tester) async {
    await _pump(tester,
        const ParseResult(values: [], error: 'Enter a price series to begin.'));
    expect(find.textContaining('Enter a price series'), findsOneWidget);
  });

  testWidgets('valid result shows the point count', (tester) async {
    await _pump(tester, const ParseResult(values: [1, 2, 3]));
    expect(find.textContaining('3 points'), findsOneWidget);
  });

  testWidgets('warning result shows the warning text', (tester) async {
    await _pump(tester,
        const ParseResult(values: [1, 2, 3], warning: 'thousands separator?'));
    expect(find.textContaining('thousands separator'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/validation_summary_test.dart`
Expected: FAIL — `validation_summary.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/ui/estimation/widgets/validation_summary.dart`:
```dart
import 'package:flutter/material.dart';

import '../../../data/services/text_input_parser.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// Live, inline summary of a [ParseResult]: a red error line, an amber warning
/// (with the green summary above it), or a green "N points · min…max" line.
/// Pure presentation — pass it the current [ParseResult].
class ValidationSummary extends StatelessWidget {
  const ValidationSummary({super.key, required this.result});

  final ParseResult result;

  // Amber advisory tone (no dedicated theme token; local to this widget).
  static const Color _amber = Color(0xFFD29922);

  @override
  Widget build(BuildContext context) {
    if (result.error != null) {
      return _Line(
        icon: Icons.error_outline,
        color: AppTheme.negative,
        text: result.error!,
      );
    }

    final summary = StringBuffer('${result.count} points');
    if (result.min != null && result.max != null) {
      summary
        ..write('  ·  min ${result.min!.toStringAsFixed(2)}')
        ..write('  ·  max ${result.max!.toStringAsFixed(2)}');
    }

    final summaryLine = _Line(
      icon: Icons.check_circle_outline,
      color: AppTheme.positive,
      text: summary.toString(),
    );

    if (result.warning != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summaryLine,
          const SizedBox(height: Spacing.xs),
          _Line(
            icon: Icons.warning_amber_outlined,
            color: _amber,
            text: result.warning!,
          ),
        ],
      );
    }
    return summaryLine;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(text, style: AppTheme.sans(fontSize: 12, color: color)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/validation_summary_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/estimation/widgets/validation_summary.dart test/ui/validation_summary_test.dart
git commit -m "feat: add ValidationSummary widget"
```

---

### Task 7: `InputPanel` widget

**Files:**
- Create: `lib/ui/estimation/widgets/input_panel.dart`
- Test: `test/ui/input_panel_test.dart`

**Interfaces:**
- Consumes: `estimationControllerProvider`, `textInputParserProvider`, `fileImportServiceProvider` (providers); `ParseResult`/`TextInputParser` (Task 2); `DtUnit` (Task 1); `ValidationSummary` (Task 6); `SectionLabel`, `Spacing`.
- Produces: `class InputPanel extends ConsumerStatefulWidget { const InputPanel({super.key}); }`. Keys: series field `Key('series-input')`, Δt value field `Key('dt-value-input')`. Compute button: a `FilledButton` labelled `Compute`.

- [ ] **Step 1: Write the failing test**

`test/ui/input_panel_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/widgets/input_panel.dart';

Future<void> _pump(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SingleChildScrollView(child: InputPanel())),
      ),
    ),
  );
}

FilledButton _computeButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Compute'));

void main() {
  testWidgets('valid seed series enables Compute', (tester) async {
    await _pump(tester);
    expect(_computeButton(tester).onPressed, isNotNull);
  });

  testWidgets('unparseable input disables Compute', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('series-input')), 'abc def');
    await tester.pump();
    expect(_computeButton(tester).onPressed, isNull);
  });

  testWidgets('fewer than 3 points disables Compute', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('series-input')), '1\n2');
    await tester.pump();
    expect(_computeButton(tester).onPressed, isNull);
  });

  testWidgets('has a Δt value field and a unit dropdown', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('dt-value-input')), findsOneWidget);
    expect(find.byType(DropdownButton<DtUnitOption>), findsOneWidget);
  });
}
```
> `DtUnitOption` is a typedef the implementation exposes so the test can name the dropdown's generic type — see Step 3.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/input_panel_test.dart`
Expected: FAIL — `input_panel.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/ui/estimation/widgets/input_panel.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/text_input_parser.dart';
import '../../../domain/value/dt_unit.dart';
import '../../../providers/providers.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/section_label.dart';
import 'validation_summary.dart';

/// Alias so widget tests can name the dropdown's generic type.
typedef DtUnitOption = DtUnit;

// Mean-reverting sample (estimated AR(1) b ≈ 0.51) so the default Compute
// shows a result rather than a non-stationary error. The earlier zig-zag seed
// had b < 0, which the estimator rejects.
const _seedSeries =
    '11.2, 10.51, 10.37, 10.32, 10.02, 10.19, 9.91, 9.89, 9.74, 9.67, 9.84, 10.1';

/// The estimation screen's input column: series text, Δt value + unit, file
/// import, live validation, and a soft-gated Compute button. Owns the text
/// controllers and the Δt/unit selection; reads estimation state via Riverpod.
class InputPanel extends ConsumerStatefulWidget {
  const InputPanel({super.key});

  @override
  ConsumerState<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends ConsumerState<InputPanel> {
  static const _parser = TextInputParser();

  final _seriesController = TextEditingController(text: _seedSeries);
  final _dtController = TextEditingController(text: '1');
  DtUnit _unit = DtUnit.steps;
  late ParseResult _parsed = _parser.parse(_seriesController.text);

  @override
  void initState() {
    super.initState();
    _seriesController.addListener(_reparse);
  }

  @override
  void dispose() {
    _seriesController.removeListener(_reparse);
    _seriesController.dispose();
    _dtController.dispose();
    super.dispose();
  }

  void _reparse() {
    setState(() => _parsed = _parser.parse(_seriesController.text));
  }

  double get _dtValue => double.tryParse(_dtController.text.trim()) ?? 0;

  bool get _canCompute => _parsed.canCompute && _dtValue > 0;

  Future<void> _importFile() async {
    final text = await ref.read(fileImportServiceProvider).pickTextFile();
    if (text == null) return;
    _seriesController.text = text.trim();
    // The listener fires on programmatic text changes too, refreshing _parsed.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Price series  ·  newline or comma separated'),
        const SizedBox(height: Spacing.sm),
        TextField(
          key: const Key('series-input'),
          controller: _seriesController,
          minLines: 2,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(
            hintText: 'e.g. 10\\n9.8\\n10.2  — or  10, 9.8, 10.2',
          ),
        ),
        const SizedBox(height: Spacing.sm),
        ValidationSummary(result: _parsed),
        const SizedBox(height: Spacing.lg),
        const SectionLabel('Sampling interval (Δt)'),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                key: const Key('dt-value-input'),
                controller: _dtController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(hintText: '1'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: DropdownButton<DtUnitOption>(
                value: _unit,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceElevated,
                items: [
                  for (final u in DtUnit.values)
                    DropdownMenuItem(value: u, child: Text('${u.label}s')),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => _unit = u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton.icon(
          onPressed: _importFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import CSV / TXT'),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: (state.loading || !_canCompute)
              ? null
              : () => notifier.compute(
                    _seriesController.text,
                    dt: _dtValue,
                    unit: _unit,
                  ),
          icon: state.loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.calculate_outlined),
          label: const Text('Compute'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: Spacing.lg),
          _ErrorBanner(message: state.error!),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/input_panel_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/estimation/widgets/input_panel.dart test/ui/input_panel_test.dart
git commit -m "feat: add InputPanel with Δt control, file import, live validation"
```

---

### Task 8: Wire `InputPanel` into the screen + `MetricsPanel` unit labels

**Files:**
- Modify: `lib/ui/estimation/estimation_screen.dart` (use `InputPanel`; drop `_buildInput` + `_ErrorBanner`)
- Modify: `lib/ui/estimation/widgets/metrics_panel.dart` (add `unitLabel`)
- Modify: `test/widget_test.dart` (keyed series finder)
- Modify: `test/ui/estimation_layout_test.dart` (keyed series finder)
- Test: `test/ui/metrics_panel_test.dart` (create)

**Interfaces:**
- Consumes: `InputPanel` (Task 7), `EstimationState.unitLabel` (Task 3).
- Produces: `MetricsPanel({required OUResult result, String unitLabel = 'step'})`.

- [ ] **Step 1: Write the failing MetricsPanel test**

`test/ui/metrics_panel_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/widgets/metrics_panel.dart';

void main() {
  testWidgets('renders the unit label on θ and half-life', (tester) async {
    const result =
        OUResult(theta: 0.3, mu: 10.0, sigma: 0.5, halfLife: 2.3);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: MetricsPanel(result: result, unitLabel: 'day'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1)); // let entrance settle
    expect(find.text('per day'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/metrics_panel_test.dart`
Expected: FAIL — `MetricsPanel` has no `unitLabel` parameter.

- [ ] **Step 3: Add `unitLabel` to MetricsPanel**

In `lib/ui/estimation/widgets/metrics_panel.dart`, update the constructor and the `items` list. Replace:
```dart
  const MetricsPanel({super.key, required this.result});

  final OUResult result;

  @override
  Widget build(BuildContext context) {
    final items = <_Metric>[
      _Metric('θ', 'Mean Reversion', result.theta.toStringAsFixed(4), 'speed'),
      _Metric('μ', 'Equilibrium', result.mu.toStringAsFixed(4), 'long-run mean'),
      _Metric('σ', 'Volatility', result.sigma.toStringAsFixed(4), 'diffusion'),
      _Metric('t½', 'Half-Life', result.halfLife.toStringAsFixed(3), 'steps'),
    ];
```
with:
```dart
  const MetricsPanel({super.key, required this.result, this.unitLabel = 'step'});

  final OUResult result;

  /// Singular Δt unit label (e.g. 'day') for θ ("per <label>") and half-life.
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final items = <_Metric>[
      _Metric('θ', 'Mean Reversion', result.theta.toStringAsFixed(4),
          'per $unitLabel'),
      _Metric('μ', 'Equilibrium', result.mu.toStringAsFixed(4), 'long-run mean'),
      _Metric('σ', 'Volatility', result.sigma.toStringAsFixed(4), 'diffusion'),
      _Metric('t½', 'Half-Life', result.halfLife.toStringAsFixed(3),
          '${unitLabel}s'),
    ];
```

- [ ] **Step 4: Run the MetricsPanel test to verify it passes**

Run: `flutter test test/ui/metrics_panel_test.dart`
Expected: PASS.

- [ ] **Step 5: Rewire the screen to use `InputPanel`**

In `lib/ui/estimation/estimation_screen.dart`:

(a) Update imports — remove `estimation_controller.dart` and `section_label.dart` if they become unused (SectionLabel is still used in `_buildResults`, so KEEP `section_label.dart`; `estimation_controller.dart` becomes unused — remove it). Add the InputPanel import:
```dart
import 'widgets/input_panel.dart';
```

(b) In `build`, the controller notifier is no longer needed. Change:
```dart
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);
```
to:
```dart
    final state = ref.watch(estimationControllerProvider);
```

(c) Replace both `_buildInput(state, notifier)` call sites with `const InputPanel()`:
- two-pane left pane child → `child: const InputPanel(),`
- single-column first child → `const InputPanel(),`

(d) Update `MetricsPanel` construction in `_buildResults`:
```dart
          MetricsPanel(result: state.result!, unitLabel: state.unitLabel),
```

(e) Delete the now-unused `_buildInput` method (lines ~90–128) and the `_ErrorBanner` class (lines ~162–190) from this file — `InputPanel` owns input and its own error banner now. Keep `_Legend` and `_EmptyHint` (still used by `_buildResults`).

- [ ] **Step 6: Update the two existing widget tests for the keyed series field**

`InputPanel` now renders two `TextField`s (series + Δt), so `find.byType(TextField)` is ambiguous. Switch those assertions to the keyed series finder.

In `test/widget_test.dart`, replace:
```dart
    expect(find.byType(TextField), findsOneWidget);
```
with:
```dart
    expect(find.byKey(const Key('series-input')), findsOneWidget);
```

In `test/ui/estimation_layout_test.dart`, both test bodies contain:
```dart
    expect(find.byType(TextField), findsOneWidget);
```
Replace each with:
```dart
    expect(find.byKey(const Key('series-input')), findsOneWidget);
```

- [ ] **Step 7: Run the full suite**

Run: `flutter test`
Expected: all green — parser(9), dt_unit(3), state(2), estimator(existing+1), controller(2), validation_summary(3), input_panel(4), metrics_panel(1), app_shell(3), estimation_layout(2), widget(1), section_label(1), glass_card(1), tokens(2).

- [ ] **Step 8: Commit**

```bash
git add lib/ui/estimation/estimation_screen.dart lib/ui/estimation/widgets/metrics_panel.dart test/widget_test.dart test/ui/estimation_layout_test.dart test/ui/metrics_panel_test.dart
git commit -m "feat: wire InputPanel into screen and label metrics with Δt unit"
```

---

### Task 9: Final verification gate

**Files:** none (verification only).

- [ ] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all pass.

- [ ] **Step 3: macOS build**

Run: `flutter build macos --debug`
Expected: `✓ Built …/ou_estimator.app`.

- [ ] **Step 4: Manual sanity (recommended)**

Run the app on macOS. Type a bad token → red line, Compute disabled. Paste a multi-line CSV with a header → first column parsed, count shown, Compute enabled. Set Δt = 5 days, Compute → θ shows "per day", half-life shows "days". Click Import CSV/TXT → file dialog opens (entitlement works).

- [ ] **Step 5: Commit any final fixes**

```bash
git add -A
git commit -m "chore: input subsystem verification pass" || echo "nothing to commit"
```

---

## Self-Review

**Spec coverage:**
- Smart paste-parse (newline-first, currency strip, thousands warning) → Task 2. ✔
- `ParseResult` shared by validation + compute → Task 2 (parser), Task 4 (compute), Task 6/7 (validation). ✔
- File import (file_picker, auto first-numeric-column, header skip) → parsing in Task 2 (`_parseLines` first-column + header skip), IO in Task 5, UI button in Task 7. ✔
- Δt value + unit feeding the math + labels → `DtUnit` (Task 1), `estimate(dt:)` wiring + persisted seconds (Task 4), control UI (Task 7), metric labels (Task 8). ✔
- Inline validation soft-gating Compute → `canCompute` (Task 2), `ValidationSummary` (Task 6), gate in `InputPanel` (Task 7). ✔
- `EstimationState.unitLabel` → Task 3. ✔
- New dep + macOS entitlements → Task 5. ✔
- Domain math untouched → Global Constraints; estimator file never edited (Task 3 only adds a test). ✔
- Tests rewrite of parser; gate analyze/test/build → Tasks 2, 9. ✔

**Placeholder scan:** No TBD/TODO/"handle edge cases". Every code step shows full code. Task 5 has no unit test by design (thin IO wrapper) — explicitly justified, verified via analyze + macOS link. ✔

**Type consistency:** `ParseResult{values,error,warning,count,min,max,canCompute}`, `TextInputParser.parse→ParseResult`, `DtUnit{label,secondsPerUnit}` + `DtUnit.steps.label=='step'`, `EstimationState.unitLabel` default `'step'`, `compute(String,{double dt=1.0,DtUnit unit=DtUnit.steps})`, `FileImportService.pickTextFile()→Future<String?>`, `fileImportServiceProvider`, `ValidationSummary({required ParseResult result})`, `InputPanel()` with keys `series-input`/`dt-value-input` and `DtUnitOption` typedef, `MetricsPanel({required OUResult result, String unitLabel='step'})` rendering `'per $unitLabel'` and `'${unitLabel}s'`. All names align across tasks. ✔

**Build-green-between-tasks note:** Task 2 changes the parser contract and the controller won't compile until Task 4; Step 5 of Task 2 flags this explicitly and Task 4 Step 5 restores a green full suite. Every other task ends green.
