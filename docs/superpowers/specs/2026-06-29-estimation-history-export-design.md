# O-U Estimator — Sub-projects #3, #4, #5 Design

**Date:** 2026-06-29  
**Features:** Estimation Depth (#3) · History UI (#4) · Export/Share (#5)  
**Approach:** Incremental — #3 → #4 → #5 in dependency order.

---

## Context

v1.0.0 shipped OLS estimation, dark theme, chart, and Isar persistence. Three planned
sub-projects remain. `OUMetrics` already has `method` (ols/mle) but is missing R²,
residual std, and log-likelihood (planned in spec, not yet implemented). `HistoryScreen`
is a placeholder empty-state. No export mechanism exists.

---

## Sub-project #3 — Estimation Depth

### `EstimationMethod` enum — moved to domain

Move `EstimationMethod` from `lib/data/models/ou_metrics.dart` to
`lib/domain/value/estimation_method.dart` (alongside `DtUnit`). Both domain
use cases and data models import from there. Preserves the dependency rule
(`data → domain`, not `domain → data`).

### Domain: `OUResult` extended

```dart
class OUResult {
  final double theta, mu, sigma, halfLife;
  final double rSquared;       // coefficient of determination on X_{t+1}
  final double residualStd;    // s (OLS: sqrt(SSE / (n-2)); MLE: transition noise)
  final double logLikelihood;  // Gaussian log-likelihood on residuals
  final int numObservations;   // n-1 pairs used
  final EstimationMethod method;
}
```

### `OUEstimator` (OLS) — additions

After existing OLS math:
- **R²:** `1 - SSE / SST` where `SST = Σ(y_i - ȳ)²`
- **residualStd:** existing `s = sqrt(SSE / (n-2))` — already computed, now returned
- **logLikelihood:** `-n/2 * log(2π) - n * log(s) - SSE / (2s²)` (Gaussian on AR(1) residuals)
- **numObservations:** `n - 1` (pairs)
- **method:** `EstimationMethod.ols`

### `MLEEstimator` (new file: `lib/domain/use_cases/mle_estimator.dart`)

Exact OU transition density:

```
X_{t+1} | X_t ~ N(m_t, v)
  m_t = μ + (X_t - μ) * e^{-θΔt}
  v   = σ² * (1 - e^{-2θΔt}) / (2θ)
```

Negative log-likelihood (minimized):

```
-L = (n-1)/2 * [log(2π) + log(v)] + 1/(2v) * Σ(x_{t+1} - m_t)²
```

**Optimizer:** Nelder-Mead simplex, pure Dart, implemented in
`lib/domain/use_cases/nelder_mead.dart`. Parameters: `[θ, μ, σ]`. Bounds enforced via
log-barrier (θ > 0, σ > 0). Initialized from OLS estimates. Convergence: 1e-8 tolerance,
max 10 000 iterations.

Returns same `OUResult` shape with `method = EstimationMethod.mle`.

### `OUMetrics` schema change

Add nullable fields (nullable = safe for existing rows without migration wipe):

```dart
double? rSquared;
double? residualStd;
double? logLikelihood;
```

`method` field already present. `numObservations` already present.

`EstimationRepository.save()` updated to persist all diagnostics.

### UI changes

- `EstimationState` adds `EstimationMethod method` (default `ols`)
- `EstimationController`:
  - Exposes `void setMethod(EstimationMethod m)` — updates state, clears result
  - `compute()` routes to `OUEstimator` or `MLEEstimator` based on `state.method`
- Input panel: `SegmentedButton<EstimationMethod>` (OLS | MLE) above Compute button
- New `DiagnosticsPanel` widget below `MetricsPanel`: 2×2 glass card grid
  - R² (coefficient of determination)
  - s (residual std)
  - ln L (log-likelihood)
  - N (observation pairs)

### Testing

- Unit: `MLEEstimator` recovers planted θ, μ, σ within 1% on synthetic AR(1) series
- Unit: `OUEstimator` returns correct R², residualStd, logLikelihood, numObservations
- Unit: `NelderMead` minimizes a known quadratic (Rosenbrock not needed; simple bowl suffices)
- Widget: `DiagnosticsPanel` renders four metric cards
- Widget: `SegmentedButton` toggles method in controller

---

## Sub-project #4 — History UI

### Data layer — `EstimationRepository` additions

```dart
Future<List<OUMetrics>> loadAll()            // newest-first by estimatedAt
Future<void> rename(int id, String newName)  // updates OUMetrics.datasetName + TimeSeriesData.name
Future<void> delete(int id)                  // deletes OUMetrics + linked TimeSeriesData in txn
```

### Navigation — `selectedTabProvider`

`AppShell` currently holds tab index as local state. Convert to:

```dart
final selectedTabProvider = StateProvider<int>((ref) => 0);
```

`AppShell` watches this; `HistoryScreen` writes to it to switch to Estimation tab after
loading a run.

### `historyProvider`

```dart
final historyProvider = FutureProvider.autoDispose<List<OUMetrics>>((ref) async {
  final repo = ref.watch(estimationRepositoryProvider);
  return repo.loadAll();
});
```

Invalidated after rename/delete.

### `HistoryScreen` — `ConsumerWidget`

Replaces the placeholder. Listens to `historyProvider`.

- **Loading state:** centered `CircularProgressIndicator`
- **Empty state:** existing icon + "Saved runs appear here" (unchanged text)
- **List:** `ListView.builder` of `HistoryRunCard`

**`HistoryRunCard`:**
- Displays: `datasetName`, method badge (`OLS` / `MLE` in accent color), θ and t½ values, relative timestamp
- Tap → `estimationController.loadFromHistory(series, samplingIntervalSeconds)` then `ref.read(selectedTabProvider.notifier).state = 0`
- Delete icon → `showDialog` confirm → `repo.delete(id)` → `ref.invalidate(historyProvider)`
- Rename via `showDialog` with `TextField` pre-filled → `repo.rename(id, newName)` → invalidate

### `EstimationController` — new method

```dart
void loadFromHistory(List<double> series, double samplingIntervalSeconds) {
  // Computes unitLabel from samplingIntervalSeconds via DtUnit
  state = EstimationState(
    series: series,
    unitLabel: _unitLabelFor(samplingIntervalSeconds),
  );
}
```

The input panel's `TextField` must also be updated to reflect loaded series text. Requires
a `TextEditingController` in `InputPanel` exposed via a key or a separate
`seriesTextProvider` that the controller writes.

> **TextEditingController sync:** Add `seriesTextProvider = StateProvider<String>((ref) => '')`
> to `providers.dart`. `InputPanel` watches it and sets `_controller.text` in its
> `build` method (guarded: only when text differs to avoid cursor jump). `loadFromHistory`
> writes `series.join('\n')` to this provider. This keeps `InputPanel` a `ConsumerStatefulWidget`
> with no direct coupling to controller internals.

### Testing

- Unit: `loadAll` returns items newest-first
- Unit: `delete` removes both OUMetrics and linked TimeSeriesData
- Unit: `rename` updates both records
- Widget: empty state renders correctly
- Widget: list renders a seeded run with correct name and method badge
- Widget: tap triggers loadFromHistory + tab switch

---

## Sub-project #5 — Export / Share

### Dependency

Add to `pubspec.yaml`:

```yaml
share_plus: ^10.0.0
```

### `ExportService` (`lib/data/services/export_service.dart`)

Pure Dart (no Flutter imports; testable):

```dart
class ExportService {
  /// From a live result (post-estimation).
  String resultToJson(OUResult result, String name, double samplingIntervalSeconds);

  /// From a stored run (history item).
  String metricsToJson(OUMetrics metrics);

  /// Triggers native share sheet.
  Future<void> share(String json, {required String runName});
}
```

**JSON schema (both methods produce same shape):**

```json
{
  "name": "AAPL_daily",
  "method": "mle",
  "estimatedAt": "2026-06-29T12:34:56.000Z",
  "samplingIntervalSeconds": 86400.0,
  "parameters": {
    "theta": 0.338, "mu": 150.2, "sigma": 0.58, "halfLife": 2.05
  },
  "diagnostics": {
    "rSquared": 0.97, "residualStd": 0.12, "logLikelihood": -45.2, "n": 251
  }
}
```

`share()` calls `Share.shareXFiles` with a `.json` temp file so the receiver gets a real
file attachment (not just plain text). Subject: `"OU Estimate: $runName"`.

### UI — share triggers

1. **Estimation screen:** `IconButton(Icons.share_rounded)` in the results section header,
   visible when `state.hasResult`. Calls `exportService.resultToJson(result, name, dt)`
   then `share()`.
2. **History list item:** trailing `IconButton(Icons.share_rounded)` on `HistoryRunCard`.
   Calls `exportService.metricsToJson(metrics)` then `share()`.

No new screen or navigation destination.

### Testing

- Unit: `resultToJson` produces valid JSON with expected keys
- Unit: `metricsToJson` produces same schema from `OUMetrics`
- Widget: share button visible when `hasResult`, absent otherwise
- Widget: share button in `HistoryRunCard` renders

---

## Architecture Summary

```
domain/value/
  estimation_method.dart      (new: EstimationMethod enum moved here from data/models)

domain/use_cases/
  ou_estimator.dart           (updated: richer OUResult)
  mle_estimator.dart          (new: exact OU MLE via Nelder-Mead)
  nelder_mead.dart            (new: simplex optimizer, pure Dart)

data/models/
  ou_metrics.dart             (updated: nullable R², residualStd, logLikelihood)

data/repositories/
  estimation_repository.dart  (updated: loadAll, rename, delete; save persists diagnostics)

data/services/
  export_service.dart         (new: JSON serialization + share_plus)

ui/estimation/
  estimation_state.dart       (updated: method field)
  estimation_controller.dart  (updated: setMethod, loadFromHistory, routes to MLE)
  widgets/
    input_panel.dart          (updated: SegmentedButton OLS|MLE)
    diagnostics_panel.dart    (new: R², s, ln L, N glass cards)

ui/history/
  history_screen.dart         (replaced: full ConsumerWidget with list)
  widgets/
    history_run_card.dart     (new: list item with load/delete/rename/share)

providers/providers.dart      (updated: selectedTabProvider, historyProvider, exportServiceProvider, seriesTextProvider)

ui/shell/app_shell.dart       (updated: watch selectedTabProvider instead of local state)
```

---

## Verification Plan

1. `fvm flutter test` — all existing 14 tests pass + new tests green
2. MLE recovery test: synthetic series from known θ=0.5, μ=10, σ=0.3; MLE estimates within 1%
3. Manual: run app, toggle OLS→MLE, compute, verify `DiagnosticsPanel` shows R², s, logLik, N
4. Manual: History tab shows saved runs; tap → series loads into Estimation screen
5. Manual: rename and delete run from History tab
6. Manual: share button → OS share sheet opens with `.json` file attachment
7. `fvm flutter analyze` — no new issues
