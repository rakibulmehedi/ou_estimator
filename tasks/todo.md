# O-U Parameter Estimator — Scaffolding Plan

> **Status:** AWAITING VERIFICATION. No app code written yet.
> **Principles:** Simplicity First · No Laziness.
> **Stack:** Flutter · Riverpod (DI + state) · Isar (local persistence).

---

## 0. What This App Does

Estimate the parameters of an **Ornstein-Uhlenbeck** mean-reverting process from a user-supplied time series.

Continuous SDE:

```
dX_t = θ (μ − X_t) dt + σ dW_t
```

Parameters to estimate:

| Symbol | Name              | Meaning                                  |
|--------|-------------------|------------------------------------------|
| θ      | mean-reversion    | speed the series pulls back to the mean  |
| μ      | long-run mean     | equilibrium level                        |
| σ      | volatility        | diffusion / noise magnitude              |

Derived: **half-life** `t½ = ln(2) / θ`.

**Estimation method (v1): OLS on the discretized AR(1) form.**
Discretize with step `Δt`:

```
X_{t+1} = a + b · X_t + ε ,   ε ~ N(0, s²)
```

Recover O-U parameters:

```
θ = −ln(b) / Δt
μ = a / (1 − b)
σ = s · sqrt( −2 ln(b) / ( Δt · (1 − b²) ) )
```

Fit quality stored: R², residual std `s`, log-likelihood, N observations.

> MLE is a future enhancement, not in v1 scope.

---

## 1. Directory Structure

Hybrid layout (data/domain by type, ui by feature):

```text
ou_estimator/
├── pubspec.yaml
├── tasks/
│   └── todo.md                       # this file
└── lib/
    ├── main.dart                     # ProviderScope + Isar init
    ├── app.dart                      # MaterialApp + routing
    ├── data/
    │   ├── models/                   # Isar collections (persistence schema)
    │   │   ├── time_series_data.dart # @collection TimeSeriesData
    │   │   └── ou_metrics.dart       # @collection OUMetrics
    │   ├── services/
    │   │   ├── isar_service.dart     # opens Isar, exposes instance
    │   │   └── text_input_parser.dart   # parse comma-separated text -> List<double>
    │   └── repositories/
    │       ├── time_series_repository.dart
    │       └── ou_metrics_repository.dart
    ├── domain/
    │   ├── models/
    │   │   └── ou_parameters.dart    # plain immutable result (freezed)
    │   └── use_cases/
    │       └── estimate_ou_use_case.dart   # OLS estimation logic
    └── ui/
        ├── core/
        │   ├── theme/                # ThemeData, typography
        │   └── widgets/              # shared widgets (loading, error)
        └── features/
            ├── import/
            │   ├── view_models/import_view_model.dart
            │   └── views/import_screen.dart
            ├── estimation/
            │   ├── view_models/estimation_view_model.dart
            │   └── views/estimation_screen.dart
            └── results/
                ├── view_models/results_view_model.dart
                └── views/results_screen.dart
```

**Dependency rule:** `ui → domain → data`. `domain` stays pure Dart (no Isar, no Flutter). Isar types live only in `data/models`; repositories map them to `domain/models`.

---

## 2. Isar Schema

### 2.1 `TimeSeriesData` (one row = one dataset)

```dart
// lib/data/models/time_series_data.dart
import 'package:isar/isar.dart';

part 'time_series_data.g.dart';

@collection
class TimeSeriesData {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;                 // dataset identifier

  late DateTime createdAt;

  /// Sampling step Δt in seconds (uniform spacing assumed for v1).
  late double samplingIntervalSeconds;

  /// Observation values in chronological order.
  late List<double> values;

  /// Optional explicit timestamps (parallel to values). May be empty
  /// when only Δt is known.
  List<DateTime> timestamps = [];

  @Backlink(to: 'dataset')
  final metrics = IsarLinks<OUMetrics>();
}
```

Design notes:
- One record per series (Simplicity First) — avoids a points table + joins.
- `name` unique-indexed → re-import replaces, keeps DB clean.
- `values` as embedded `List<double>` is sufficient for utility-scale data.

### 2.2 `OUMetrics` (one row = one estimation result)

```dart
// lib/data/models/ou_metrics.dart
import 'package:isar/isar.dart';
import 'time_series_data.dart';

part 'ou_metrics.g.dart';

enum EstimationMethod { ols, mle }   // mle reserved for future

@collection
class OUMetrics {
  Id id = Isar.autoIncrement;

  @Index()
  late String datasetName;          // denormalized for fast lookup

  // --- Estimated O-U parameters ---
  late double theta;                // mean-reversion speed
  late double mu;                   // long-run mean
  late double sigma;                // volatility

  // --- Derived ---
  late double halfLife;             // ln(2)/theta

  // --- Fit quality ---
  late double rSquared;
  late double residualStd;          // s
  late double logLikelihood;
  late int numObservations;         // N

  @enumerated
  late EstimationMethod method;     // = EstimationMethod.ols for v1

  late DateTime estimatedAt;

  final dataset = IsarLink<TimeSeriesData>();
}
```

Relation: `OUMetrics.dataset` ↔ `TimeSeriesData.metrics` (one dataset, many estimation runs).

---

## 3. Riverpod Providers

Riverpod replaces the skill's `ChangeNotifier` MVVM: providers do DI, `AsyncNotifier`/`Notifier` hold screen state.

### 3.1 Infrastructure / DI

```dart
// Isar instance — async open, app-wide singleton.
final isarProvider = FutureProvider<Isar>((ref) async {
  return ref.watch(isarServiceProvider).db;   // opened in IsarService
});

final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

final textInputParserProvider =
    Provider<TextInputParser>((ref) => TextInputParser());
```

### 3.2 Repositories

```dart
final timeSeriesRepositoryProvider = Provider<TimeSeriesRepository>((ref) {
  return TimeSeriesRepository(ref.watch(isarServiceProvider));
});

final ouMetricsRepositoryProvider = Provider<OUMetricsRepository>((ref) {
  return OUMetricsRepository(ref.watch(isarServiceProvider));
});
```

### 3.3 Use Case (pure domain)

```dart
final estimateOUUseCaseProvider =
    Provider<EstimateOUUseCase>((ref) => EstimateOUUseCase());
```

### 3.4 ViewModels (feature state)

```dart
// Import screen: pick file, parse, persist dataset.
final importViewModelProvider =
    AsyncNotifierProvider<ImportViewModel, ImportState>(ImportViewModel.new);

// Estimation screen: run OLS, persist OUMetrics.
final estimationViewModelProvider =
    AsyncNotifierProvider<EstimationViewModel, EstimationState>(
        EstimationViewModel.new);

// Results screen: read stored datasets + their metrics.
final resultsViewModelProvider =
    AsyncNotifierProvider<ResultsViewModel, ResultsState>(ResultsViewModel.new);
```

Each ViewModel reads its repositories / use case via `ref` — constructor injection equivalent under Riverpod.

---

## 4. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.0
  # NO file_picker / csv — input is manual comma-separated text only (locked §6.2)
  freezed_annotation: ^2.4.0
  fl_chart: ^0.68.0          # series + fit visualization (MANDATORY, locked §6.5)

dev_dependencies:
  build_runner: ^2.4.0
  isar_generator: ^3.1.0
  freezed: ^2.5.0
```

---

## 5. Execution Checklist (after verification)

- [x] **Step 1.** `flutter create` (org com.ouestimator; android/ios/macos). Final deps in `pubspec.yaml`. ✅ DONE.
  - Pivoted `isar`/`isar_generator` 3.1.0 → **`isar_community` 3.3.2** trio: original codegen pins `analyzer <6.0.0`, incompatible with Dart 3.12. Dropped standalone `test` (clashed with `flutter_test`'s `test_api`); math tests now run under `flutter_test`.
- [x] **Step 2.** Directory tree per §1 (data/domain/ui). ✅ DONE.
- [x] **Step 3.** Isar models `TimeSeriesData` + `OUMetrics` (import `package:isar_community/isar.dart`). `build_runner` generated both `*.g.dart`. ✅ DONE.
- [x] **Step 4.** `IsarService.open()` — opens both schemas via `path_provider`. ✅ DONE.
- [x] **Step 5.** `main.dart` — async Isar open, `ProviderScope` with `isarProvider` override, dark `MaterialApp`. ✅ DONE.
- [x] **Step 6.** `EstimationRepository` — persists dataset + linked metrics in a write txn (single source of truth). ✅ DONE.
- [x] **Step 7.** ~~freezed `ou_parameters.dart`~~ — used existing plain immutable `OUResult` (Phase 3 single screen; freezed dropped, Simplicity First). ✅ DONE.
- [x] **Step 8.** Implement OLS estimator + tests. ✅ DONE.
  - `OUEstimator` (pure Dart, `dart:math` only) at `lib/domain/use_cases/ou_estimator.dart`; returns `OUResult{theta, mu, sigma, halfLife}`.
  - Tests at `test/ou_estimator_test.dart` — 4/4 passing under Dart 3.12.1 (`fvm stable`).
  - Recovery check (planted b=0.7, μ=10): θ=0.338, μ=9.79, σ=0.58, half-life=2.05.
  - Exceptions: `length < 3` → `InsufficientDataException`; `b >= 1` → `NonStationaryException` (also b≤0 / zero-variance).
  - NOTE: request said "MLE using OLS" — implemented as **OLS** (true MLE deferred per locked §6.3).
  - NOTE: pure random walk has downward OLS bias on b, so the non-stationary test uses an explosive series (b≈1.01) to deterministically exercise `b >= 1`.
- [x] **Step 9.** `TextInputParser` (comma/whitespace text → `List<double>`, `FormatException` on bad token) + 5 tests. ✅ DONE.
- [x] **Step 10.** `EstimationController` (`Notifier<EstimationState>`) — parse → estimate → persist; maps exceptions to friendly errors. Riverpod providers in `lib/providers/providers.dart`. (Used `Notifier` not `AsyncNotifier`: compute path is sync.) ✅ DONE.
- [x] **Step 11.** Single-screen UI (`EstimationScreen` ConsumerStatefulWidget): TextField, Compute button, `MetricsPanel` (θ/μ/σ/t½), `PriceChart` (fl_chart, dynamic Y min/max, red dashed μ line), dark theme. ✅ DONE.
- [x] **Step 12.** ~~Multi-screen routing~~ — single `home: EstimationScreen` (Phase 3 = one screen). ✅ DONE.
- [x] **Step 13.** Validator. ✅ DONE.
  - `flutter analyze` → **No issues found!** (`.g.dart` excluded — Isar fork uses experimental index APIs).
  - `flutter test` → **+10 all passed** (4 math · 5 parser · 1 widget smoke).
  - `flutter build macos --debug` → **✓ Built** (full link incl. Isar native libs; Android AAB blocked here — cmdline-tools/licenses missing; commands handed off).

---

## 6. Verification Outcome (LOCKED)

1. **Δt handling** — ✅ Uniform Δt only. No irregular-timestamp support in v1.
2. **Input format** — ✅ Manual comma-separated text input ONLY. No CSV, no file picker, no storage/file permissions. Drop `file_picker` + `csv` deps; replace `CsvImportService` with `TextInputParser`.
3. **Estimation method** — ✅ Discrete OLS approved for v1. MLE deferred to future enhancement.
4. **State management** — `AsyncNotifier` per screen (current plan), unchanged.
5. **Charting** — ✅ `fl_chart` visualization MANDATORY for the UI layer.

---

## 7. Phase 4 — Premium Fintech Dark UI Overhaul (DONE)

Scope-locked: edited ONLY `pubspec.yaml`, `lib/ui/core/theme.dart`,
`lib/ui/estimation/widgets/metrics_panel.dart`,
`lib/ui/estimation/widgets/price_chart.dart`. Zero changes to
domain/data/providers/controller/state. Widgets remain pure `StatelessWidget`
consumers (no `ref`, no new state/providers).

- **Fonts (offline strategy):** bundled Inter (4 weights) + JetBrains Mono
  (4 weights) static TTFs into `assets/google_fonts/` (OFL). google_fonts
  resolves them from assets → offline release render, no first-paint FOUT.
  `main.dart` untouched (asset presence alone short-circuits runtime fetch).
- **theme.dart:** token set (background #0D1117, surface, surfaceElevated,
  border, accent #4F8CFF, textPrimary/secondary/tertiary, positive/negative,
  glass fill/border). Inter body via `interTextTheme`; `AppTheme.mono()` =
  JetBrains Mono + tabular figures for all numerics. `dark` cached as
  `static final`.
- **metrics_panel.dart:** glass cards (8% white fill, 12% hairline,
  BackdropFilter blur, radius 16) + staggered `flutter_animate`
  (delay i·80ms, fadeIn 400ms, slideY 0.1→0). Semantics labels +
  RepaintBoundary. Numbers in mono.
- **price_chart.dart:** curved line, accent→transparent vertical gradient fill,
  enabled touch w/ dark tooltip (mono price) + glowing accent dot. Empty/1-pt
  guard, RepaintBoundary, Semantics, static title builders.

### Verification
- `fvm flutter analyze` → **No issues found!** (zero new warnings)
- `fvm flutter test` → **+10 all passed**. **No test files touched** —
  `widget_test` renders `EstimationScreen` pre-compute, so the changed widgets
  never mount; finders (`Compute`, `TextField`) unchanged.
- `flutter-reviewer` agent + `flutter-dart-code-review` → 0 CRITICAL. Fixed
  2 HIGH (empty-series crash guard; per-card RepaintBoundary) + 6 MEDIUM
  (cached theme, hoisted styles, float-safe tick modulo, unit contrast→AA,
  Semantics ×2) + 1 LOW (static title fns). Rejected 1 LOW (μ→amber): would
  desync the scope-locked legend swatch in `estimation_screen.dart`.

### BLOCKER — release signing (TASK 5, STOPPED as instructed)
- `android/key.properties` **does not exist**.
- `android/app/build.gradle.kts:32` release uses
  `signingConfig = signingConfigs.getByName("debug")`.
- A `--release` AAB here would be **debug-signed = NOT release-signed**.
  Per instruction, STOPPED before building. Need a real keystore +
  `key.properties` + release `signingConfig` wired in before a signed AAB
  can be produced.
