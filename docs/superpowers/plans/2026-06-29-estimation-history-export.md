# Estimation Depth · History UI · Export/Share Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add MLE estimator + fit diagnostics (#3), history list with load/rename/delete (#4), and JSON export via native share sheet (#5).

**Architecture:** Incremental — #3 lays the richer `OUResult`/`OUMetrics` foundation; #4 adds history read/write + navigation lift; #5 adds `ExportService` + share buttons. Each sub-project ends with a full green test run.

**Tech Stack:** Flutter · Riverpod 2 · Isar Community 3.3.2 · fl_chart · share_plus ^10.0.0 · pure-Dart Nelder-Mead (no external optimizer)

## Global Constraints

- Flutter SDK: `fvm flutter` (not bare `flutter`) for all commands
- Import Isar as `package:isar_community/isar.dart`
- Domain layer (`lib/domain/`) must import nothing from `lib/data/` or Flutter
- State management: Riverpod `Notifier` / `FutureProvider` — no `ChangeNotifier`
- All new `.dart` files must pass `fvm flutter analyze` with zero issues
- Tests: `fvm flutter test` — must stay green after every commit
- Run `build_runner` after any Isar model change: `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- `fvm flutter test` base line: 14 widget tests + existing unit tests all pass

---

## File Map

**New files:**
- `lib/domain/value/estimation_method.dart` — `EstimationMethod` enum (moved from data layer)
- `lib/domain/use_cases/nelder_mead.dart` — Nelder-Mead simplex optimizer
- `lib/domain/use_cases/mle_estimator.dart` — MLE estimator via Nelder-Mead
- `lib/data/services/export_service.dart` — JSON serialization + share_plus
- `lib/ui/estimation/widgets/diagnostics_panel.dart` — R², s, ln L, N glass cards
- `lib/ui/history/widgets/history_run_card.dart` — list item (load/rename/delete/share)
- `test/nelder_mead_test.dart`
- `test/mle_estimator_test.dart`
- `test/export_service_test.dart`
- `test/ui/diagnostics_panel_test.dart`
- `test/ui/history_run_card_test.dart`

**Modified files:**
- `lib/domain/use_cases/ou_estimator.dart` — extend `OUResult`; compute diagnostics
- `lib/data/models/ou_metrics.dart` — import enum from domain; add nullable diagnostics + `samplingIntervalSeconds`
- `lib/data/repositories/estimation_repository.dart` — save diagnostics; add `loadAll`/`rename`/`delete`
- `lib/ui/estimation/estimation_state.dart` — add `method`, `samplingIntervalSeconds`
- `lib/ui/estimation/estimation_controller.dart` — add `setMethod`, `loadFromHistory`; route OLS/MLE
- `lib/ui/estimation/widgets/input_panel.dart` — add `SegmentedButton` OLS|MLE; watch `seriesTextProvider`
- `lib/ui/estimation/estimation_screen.dart` — show `DiagnosticsPanel`; share button
- `lib/ui/history/history_screen.dart` — replace placeholder with full list
- `lib/ui/shell/app_shell.dart` — `ConsumerWidget` watching `selectedTabProvider`
- `lib/providers/providers.dart` — add `selectedTabProvider`, `seriesTextProvider`, `historyProvider`, `mlEstimatorProvider`, `exportServiceProvider`

---

## Sub-project #3 — Estimation Depth

---

### Task 1: Move `EstimationMethod` to domain layer

**Files:**
- Create: `lib/domain/value/estimation_method.dart`
- Modify: `lib/data/models/ou_metrics.dart`

**Interfaces:**
- Produces: `EstimationMethod` enum at `lib/domain/value/estimation_method.dart`; imported by `ou_metrics.dart`, `ou_estimator.dart`, `mle_estimator.dart`, `estimation_state.dart`

- [ ] **Step 1: Create the enum file**

```dart
// lib/domain/value/estimation_method.dart

/// Estimation method used to fit the O-U parameters.
/// mle is added in sub-project #3.
enum EstimationMethod { ols, mle }
```

- [ ] **Step 2: Update `ou_metrics.dart` to import from domain**

Replace the existing file `lib/data/models/ou_metrics.dart` with:

```dart
import 'package:isar_community/isar.dart';

import '../../domain/value/estimation_method.dart';
import 'time_series_data.dart';

part 'ou_metrics.g.dart';

/// One stored estimation result for a dataset.
@collection
class OUMetrics {
  Id id = Isar.autoIncrement;

  /// Denormalized for fast lookup without traversing the link.
  @Index()
  late String datasetName;

  late double theta;
  late double mu;
  late double sigma;
  late double halfLife;
  late int numObservations;

  @enumerated
  late EstimationMethod method;

  late DateTime estimatedAt;

  final dataset = IsarLink<TimeSeriesData>();
}
```

- [ ] **Step 3: Run build_runner**

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `[INFO] Build completed successfully!` (no errors)

- [ ] **Step 4: Run existing tests**

```bash
fvm flutter test
```

Expected: all tests pass. If any import `EstimationMethod` from `ou_metrics.dart`, update those imports to `lib/domain/value/estimation_method.dart`.

- [ ] **Step 5: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/domain/value/estimation_method.dart lib/data/models/ou_metrics.dart lib/data/models/ou_metrics.g.dart
git commit -m "refactor: move EstimationMethod enum to domain layer"
```

---

### Task 2: Extend `OUResult` + `OUEstimator` with fit diagnostics

**Files:**
- Modify: `lib/domain/use_cases/ou_estimator.dart`
- Modify: `test/ou_estimator_test.dart` (add diagnostic assertions)

**Interfaces:**
- Produces: `OUResult` with fields `rSquared`, `residualStd`, `logLikelihood`, `numObservations`, `method` — all subsequent tasks use this shape

- [ ] **Step 1: Write new diagnostic tests (they will fail)**

Add to `test/ou_estimator_test.dart` (after the existing tests):

```dart
  test('E: rSquared is in [0, 1] for mean-reverting series', () {
    final series = _meanReverting();
    final result = OUEstimator().estimate(series);
    expect(result.rSquared, inInclusiveRange(0.0, 1.0));
  });

  test('F: residualStd is positive and finite', () {
    final series = _meanReverting();
    final result = OUEstimator().estimate(series);
    expect(result.residualStd, greaterThan(0));
    expect(result.residualStd.isFinite, isTrue);
  });

  test('G: logLikelihood is finite', () {
    final series = _meanReverting();
    final result = OUEstimator().estimate(series);
    expect(result.logLikelihood.isFinite, isTrue);
  });

  test('H: numObservations equals series.length - 1', () {
    final series = _meanReverting(n: 100);
    final result = OUEstimator().estimate(series);
    expect(result.numObservations, 99);
  });

  test('I: method is ols', () {
    final result =
        OUEstimator().estimate([10.0, 9.5, 10.2, 9.8, 10.1]);
    expect(result.method, EstimationMethod.ols);
  });
```

Add import at top of `test/ou_estimator_test.dart`:
```dart
import 'package:ou_estimator/domain/value/estimation_method.dart';
```

- [ ] **Step 2: Run new tests to confirm they fail**

```bash
fvm flutter test test/ou_estimator_test.dart
```

Expected: tests E–I fail with `Class 'OUResult' has no instance getter 'rSquared'` or similar.

- [ ] **Step 3: Replace `lib/domain/use_cases/ou_estimator.dart`**

```dart
import 'dart:math' as math;

import '../value/estimation_method.dart';

/// Immutable result of an O-U parameter estimation.
class OUResult {
  const OUResult({
    required this.theta,
    required this.mu,
    required this.sigma,
    required this.halfLife,
    required this.rSquared,
    required this.residualStd,
    required this.logLikelihood,
    required this.numObservations,
    required this.method,
  });

  final double theta;
  final double mu;
  final double sigma;
  final double halfLife;
  final double rSquared;      // coefficient of determination on X_{t+1}
  final double residualStd;   // OLS: sqrt(SSE / (n-2))
  final double logLikelihood; // Gaussian log-likelihood at OLS variance
  final int numObservations;  // n-1 pairs used in regression
  final EstimationMethod method;

  @override
  String toString() =>
      'OUResult(theta: $theta, mu: $mu, sigma: $sigma, halfLife: $halfLife, '
      'R²: $rSquared, s: $residualStd, logL: $logLikelihood, '
      'N: $numObservations, method: $method)';
}

/// Thrown when the series is too short to estimate.
class InsufficientDataException implements Exception {
  final String message;
  const InsufficientDataException(this.message);
  @override
  String toString() => 'InsufficientDataException: $message';
}

/// Thrown when the series is not mean-reverting.
class NonStationaryException implements Exception {
  final String message;
  const NonStationaryException(this.message);
  @override
  String toString() => 'NonStationaryException: $message';
}

/// Estimates O-U parameters via OLS on the discretized AR(1) form.
///
///   dX = theta*(mu - X)*dt + sigma*dW
///   X_{t+1} = a + b*X_t + eps,   eps ~ N(0, s^2)
///
/// Recovery:
///   theta    = -ln(b) / dt
///   mu       = a / (1 - b)
///   sigma    = s * sqrt( 2*theta / (1 - b^2) )
///   halfLife = ln(2) / theta
class OUEstimator {
  static const int minLength = 3;

  OUResult estimate(List<double> series, {double dt = 1.0}) {
    if (series.length < minLength) {
      throw InsufficientDataException(
        'Need at least $minLength observations, got ${series.length}.',
      );
    }
    if (dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'must be > 0');
    }

    final n = series.length - 1;
    final x = series.sublist(0, n);
    final y = series.sublist(1, n + 1);

    final meanX = _mean(x);
    final meanY = _mean(y);

    double sxx = 0.0;
    double sxy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      sxx += dx * dx;
      sxy += dx * (y[i] - meanY);
    }

    if (sxx == 0.0) {
      throw const NonStationaryException(
        'Input series is constant (zero variance); cannot estimate.',
      );
    }

    final b = sxy / sxx;
    final a = meanY - b * meanX;

    if (b >= 1.0) {
      throw NonStationaryException(
        'Estimated AR(1) coefficient b=$b >= 1 (non-stationary / not mean-reverting).',
      );
    }
    if (b <= 0.0) {
      throw NonStationaryException(
        'Estimated AR(1) coefficient b=$b <= 0 (no valid mean reversion).',
      );
    }

    // Residuals
    double sse = 0.0;
    double sst = 0.0;
    for (var i = 0; i < n; i++) {
      final resid = y[i] - (a + b * x[i]);
      sse += resid * resid;
      final dy = y[i] - meanY;
      sst += dy * dy;
    }

    final dof = n > 2 ? n - 2 : 1;
    final s = math.sqrt(sse / dof);

    final rSquared = sst == 0.0 ? 1.0 : 1.0 - sse / sst;

    // Gaussian log-likelihood at OLS residual variance
    final logLikelihood =
        -n / 2.0 * math.log(2 * math.pi) - n * math.log(s) - sse / (2 * s * s);

    final theta = -math.log(b) / dt;
    final mu = a / (1.0 - b);
    final sigma = s * math.sqrt(2.0 * theta / (1.0 - b * b));
    final halfLife = math.log(2) / theta;

    return OUResult(
      theta: theta,
      mu: mu,
      sigma: sigma,
      halfLife: halfLife,
      rSquared: rSquared,
      residualStd: s,
      logLikelihood: logLikelihood,
      numObservations: n,
      method: EstimationMethod.ols,
    );
  }

  double _mean(List<double> v) {
    var sum = 0.0;
    for (final e in v) {
      sum += e;
    }
    return sum / v.length;
  }
}
```

- [ ] **Step 4: Run all tests**

```bash
fvm flutter test
```

Expected: all previous tests + new tests E–I pass. The existing tests A–D access `.theta`, `.mu`, etc. by name — they still compile. Check that `estimation_state_test.dart` still passes (it doesn't construct `OUResult` directly).

- [ ] **Step 5: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/domain/use_cases/ou_estimator.dart test/ou_estimator_test.dart
git commit -m "feat: extend OUResult with fit diagnostics (R², s, logL, N, method)"
```

---

### Task 3: Nelder-Mead simplex optimizer

**Files:**
- Create: `lib/domain/use_cases/nelder_mead.dart`
- Create: `test/nelder_mead_test.dart`

**Interfaces:**
- Produces: `NelderMead.minimize(f, x0, {tolerance, maxIter}) → List<double>` — used only by `MLEEstimator`

- [ ] **Step 1: Write failing tests**

```dart
// test/nelder_mead_test.dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/nelder_mead.dart';

void main() {
  test('minimizes x^2 + y^2 to near (0, 0)', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) => p[0] * p[0] + p[1] * p[1],
      [1.0, 1.0],
    );
    expect(result[0], closeTo(0.0, 1e-4));
    expect(result[1], closeTo(0.0, 1e-4));
  });

  test('minimizes (x-3)^2 + (y+2)^2 to near (3, -2)', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) {
        final dx = p[0] - 3;
        final dy = p[1] + 2;
        return dx * dx + dy * dy;
      },
      [0.0, 0.0],
    );
    expect(result[0], closeTo(3.0, 1e-4));
    expect(result[1], closeTo(-2.0, 1e-4));
  });

  test('minimizes a 3D quadratic near the origin', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) => p[0] * p[0] + p[1] * p[1] + p[2] * p[2],
      [5.0, -3.0, 2.0],
    );
    expect(result[0], closeTo(0.0, 1e-4));
    expect(result[1], closeTo(0.0, 1e-4));
    expect(result[2], closeTo(0.0, 1e-4));
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
fvm flutter test test/nelder_mead_test.dart
```

Expected: `Target file "test/nelder_mead_test.dart" not found` or `Cannot find 'NelderMead'`.

- [ ] **Step 3: Implement `NelderMead`**

```dart
// lib/domain/use_cases/nelder_mead.dart
import 'dart:math' as math;

/// Nelder-Mead simplex optimizer. Minimizes a scalar function over R^n.
///
/// Standard parameters: α=1 (reflection), γ=2 (expansion),
/// ρ=0.5 (contraction), σ=0.5 (shrink).
class NelderMead {
  const NelderMead({
    this.alpha = 1.0,
    this.gamma = 2.0,
    this.rho = 0.5,
    this.sigma = 0.5,
  });

  final double alpha;
  final double gamma;
  final double rho;
  final double sigma;

  /// Returns the minimizer of [f] starting from [x0].
  List<double> minimize(
    double Function(List<double>) f,
    List<double> x0, {
    double tolerance = 1e-8,
    int maxIter = 10000,
  }) {
    final n = x0.length;

    // Build n+1 initial simplex vertices.
    final simplex = List<List<double>>.generate(n + 1, (i) {
      final p = List<double>.of(x0);
      if (i > 0) {
        // Perturb the (i-1)-th coordinate by 5% of its magnitude or 0.00025.
        p[i - 1] +=
            p[i - 1].abs() > 1e-12 ? 0.05 * p[i - 1].abs() : 0.00025;
      }
      return p;
    });
    final fv = simplex.map(f).toList();

    for (var iter = 0; iter < maxIter; iter++) {
      // Sort vertices by ascending function value.
      final idx = List.generate(n + 1, (i) => i)
        ..sort((a, b) => fv[a].compareTo(fv[b]));
      final sTmp = idx.map((i) => simplex[i]).toList();
      final fTmp = idx.map((i) => fv[i]).toList();
      for (var i = 0; i <= n; i++) {
        simplex[i] = sTmp[i];
        fv[i] = fTmp[i];
      }

      // Convergence: max Euclidean distance from best vertex.
      var maxDist = 0.0;
      for (var i = 1; i <= n; i++) {
        var d = 0.0;
        for (var j = 0; j < n; j++) {
          final diff = simplex[i][j] - simplex[0][j];
          d += diff * diff;
        }
        if (d > maxDist) maxDist = d;
      }
      if (math.sqrt(maxDist) < tolerance) break;

      // Centroid of all but the worst vertex (simplex[n]).
      final c = List.filled(n, 0.0);
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          c[j] += simplex[i][j] / n;
        }
      }

      // Reflection.
      final xr =
          List.generate(n, (j) => c[j] + alpha * (c[j] - simplex[n][j]));
      final fr = f(xr);

      if (fr < fv[0]) {
        // Try expansion.
        final xe = List.generate(n, (j) => c[j] + gamma * (xr[j] - c[j]));
        final fe = f(xe);
        simplex[n] = fe < fr ? xe : xr;
        fv[n] = fe < fr ? fe : fr;
      } else if (fr < fv[n - 1]) {
        // Accept reflection.
        simplex[n] = xr;
        fv[n] = fr;
      } else {
        // Contraction.
        final xc = List.generate(
            n, (j) => c[j] + rho * (simplex[n][j] - c[j]));
        final fc = f(xc);
        if (fc < fv[n]) {
          simplex[n] = xc;
          fv[n] = fc;
        } else {
          // Shrink all but the best vertex.
          for (var i = 1; i <= n; i++) {
            simplex[i] = List.generate(
              n,
              (j) => simplex[0][j] + sigma * (simplex[i][j] - simplex[0][j]),
            );
            fv[i] = f(simplex[i]);
          }
        }
      }
    }

    return simplex[0];
  }
}
```

- [ ] **Step 4: Run tests**

```bash
fvm flutter test test/nelder_mead_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 5: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/domain/use_cases/nelder_mead.dart test/nelder_mead_test.dart
git commit -m "feat: add Nelder-Mead simplex optimizer (pure Dart)"
```

---

### Task 4: MLE estimator

**Files:**
- Create: `lib/domain/use_cases/mle_estimator.dart`
- Create: `test/mle_estimator_test.dart`

**Interfaces:**
- Consumes: `NelderMead.minimize`, `OUEstimator.minLength`, `OUResult` (Task 2), `EstimationMethod.mle` (Task 1)
- Produces: `MLEEstimator.estimate(List<double>, {double dt}) → OUResult` with `method = EstimationMethod.mle`

- [ ] **Step 1: Write failing tests**

```dart
// test/mle_estimator_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/mle_estimator.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';

// Reuse the same AR(1) generator from ou_estimator_test.dart
double _gauss(Random r) {
  final u1 = max(r.nextDouble(), 1e-12);
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * r.nextDouble());
}

List<double> _meanReverting({
  int n = 1000,
  double b = 0.7,
  double mu = 10.0,
  double noise = 0.5,
  int seed = 42,
}) {
  final r = Random(seed);
  final a = mu * (1 - b);
  final out = <double>[mu];
  for (var i = 1; i < n; i++) {
    out.add(a + b * out.last + noise * _gauss(r));
  }
  return out;
}

void main() {
  test('returns method = mle', () {
    final result = MLEEstimator()
        .estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.method, EstimationMethod.mle);
  });

  test('theta is positive', () {
    final result = MLEEstimator()
        .estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.theta, greaterThan(0));
  });

  test('mu recovers planted value within 2 units (n=1000)', () {
    final result = MLEEstimator()
        .estimate(_meanReverting(n: 1000), dt: 1.0);
    expect(result.mu, closeTo(10.0, 2.0));
  });

  test('sigma is positive and finite', () {
    final result = MLEEstimator()
        .estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.sigma, greaterThan(0));
    expect(result.sigma.isFinite, isTrue);
  });

  test('rSquared is in [0, 1]', () {
    final result = MLEEstimator()
        .estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.rSquared, inInclusiveRange(0.0, 1.0));
  });

  test('numObservations equals series.length - 1', () {
    final series = _meanReverting(n: 150);
    final result = MLEEstimator().estimate(series, dt: 1.0);
    expect(result.numObservations, 149);
  });

  test('throws InsufficientDataException when series.length < 3', () {
    expect(
      () => MLEEstimator().estimate([1.0, 2.0]),
      throwsA(isA<InsufficientDataException>()),
    );
  });

  test('throws ArgumentError when dt <= 0', () {
    expect(
      () => MLEEstimator().estimate(_meanReverting(n: 50), dt: 0.0),
      throwsA(isA<ArgumentError>()),
    );
  });
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
fvm flutter test test/mle_estimator_test.dart
```

Expected: `Cannot find 'MLEEstimator'`.

- [ ] **Step 3: Implement `MLEEstimator`**

```dart
// lib/domain/use_cases/mle_estimator.dart
import 'dart:math' as math;

import '../value/estimation_method.dart';
import 'nelder_mead.dart';
import 'ou_estimator.dart';

/// Estimates O-U parameters via MLE on the exact transition density.
///
/// Transition: X_{t+1} | X_t ~ N(m_t, v)
///   m_t = μ + (X_t - μ) * e^{-θΔt}
///   v   = σ² (1 - e^{-2θΔt}) / (2θ)
///
/// Minimizes the negative log-likelihood using Nelder-Mead, initialized
/// from the OLS solution.
class MLEEstimator {
  MLEEstimator({NelderMead? optimizer})
      : _optimizer = optimizer ?? const NelderMead();

  final NelderMead _optimizer;

  OUResult estimate(List<double> series, {double dt = 1.0}) {
    if (series.length < OUEstimator.minLength) {
      throw InsufficientDataException(
        'Need at least ${OUEstimator.minLength} observations, '
        'got ${series.length}.',
      );
    }
    if (dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'must be > 0');
    }

    final n = series.length - 1;
    final x = series.sublist(0, n);
    final y = series.sublist(1);

    // Initialize from OLS
    final ols = OUEstimator().estimate(series, dt: dt);

    double negLogLik(List<double> params) {
      final theta = params[0];
      final mu = params[1];
      final sigma = params[2];
      if (theta <= 0 || sigma <= 0) return 1e30;

      final eFac = math.exp(-theta * dt);
      final v = sigma * sigma * (1 - math.exp(-2 * theta * dt)) / (2 * theta);
      if (v <= 0) return 1e30;

      var sumSq = 0.0;
      for (var i = 0; i < n; i++) {
        final mt = mu + (x[i] - mu) * eFac;
        final diff = y[i] - mt;
        sumSq += diff * diff;
      }
      return n / 2.0 * (math.log(2 * math.pi) + math.log(v)) +
          sumSq / (2 * v);
    }

    final best = _optimizer.minimize(
      negLogLik,
      [ols.theta, ols.mu, ols.sigma],
      tolerance: 1e-8,
      maxIter: 10000,
    );

    final theta = best[0];
    final mu = best[1];
    final sigma = best[2];

    if (theta <= 0) {
      throw NonStationaryException(
        'MLE: estimated θ=$theta ≤ 0 — series is not mean-reverting.',
      );
    }

    // Compute diagnostics at MLE solution.
    final eFac = math.exp(-theta * dt);
    final v = sigma * sigma * (1 - math.exp(-2 * theta * dt)) / (2 * theta);

    var sse = 0.0;
    final meanY = y.reduce((a, b) => a + b) / n;
    var sst = 0.0;
    for (var i = 0; i < n; i++) {
      final mt = mu + (x[i] - mu) * eFac;
      final diff = y[i] - mt;
      sse += diff * diff;
      final dy = y[i] - meanY;
      sst += dy * dy;
    }

    final rSquared = sst == 0.0 ? 1.0 : 1.0 - sse / sst;
    final residualStd = math.sqrt(v); // MLE transition std dev
    final logLikelihood = -negLogLik(best);
    final halfLife = math.log(2) / theta;

    return OUResult(
      theta: theta,
      mu: mu,
      sigma: sigma,
      halfLife: halfLife,
      rSquared: rSquared,
      residualStd: residualStd,
      logLikelihood: logLikelihood,
      numObservations: n,
      method: EstimationMethod.mle,
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
fvm flutter test test/mle_estimator_test.dart
```

Expected: 8 tests pass. MLE tests are slower than OLS (~1-2s for n=1000).

- [ ] **Step 5: Run full suite**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/use_cases/mle_estimator.dart test/mle_estimator_test.dart
git commit -m "feat: add MLE estimator for O-U parameters via Nelder-Mead"
```

---

### Task 5: Update `OUMetrics` schema + `EstimationRepository.save()`

**Files:**
- Modify: `lib/data/models/ou_metrics.dart`
- Modify: `lib/data/repositories/estimation_repository.dart`

**Interfaces:**
- Consumes: `OUResult.rSquared`, `.residualStd`, `.logLikelihood`, `.numObservations`, `.method` (Task 2)
- Produces: `OUMetrics` with nullable `rSquared?`, `residualStd?`, `logLikelihood?`, `samplingIntervalSeconds?`; `EstimationRepository.save()` persists all diagnostics

- [ ] **Step 1: Update `OUMetrics`**

Replace `lib/data/models/ou_metrics.dart`:

```dart
import 'package:isar_community/isar.dart';

import '../../domain/value/estimation_method.dart';
import 'time_series_data.dart';

part 'ou_metrics.g.dart';

/// One stored estimation result for a dataset.
@collection
class OUMetrics {
  Id id = Isar.autoIncrement;

  @Index()
  late String datasetName;

  late double theta;
  late double mu;
  late double sigma;
  late double halfLife;
  late int numObservations;

  // Nullable so existing rows (written before this schema version) stay valid.
  double? rSquared;
  double? residualStd;
  double? logLikelihood;
  double? samplingIntervalSeconds;

  @enumerated
  late EstimationMethod method;

  late DateTime estimatedAt;

  final dataset = IsarLink<TimeSeriesData>();
}
```

- [ ] **Step 2: Regenerate Isar code**

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `[INFO] Build completed successfully!`

- [ ] **Step 3: Update `EstimationRepository.save()`**

Replace `lib/data/repositories/estimation_repository.dart`:

```dart
import 'package:isar_community/isar.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../models/ou_metrics.dart';
import '../models/time_series_data.dart';

/// Persists a dataset and its estimation result.
class EstimationRepository {
  EstimationRepository(this._isar);

  final Isar _isar;

  Future<void> save({
    required String name,
    required List<double> series,
    required double samplingIntervalSeconds,
    required OUResult result,
  }) async {
    await _isar.writeTxn(() async {
      final dataset = TimeSeriesData()
        ..name = name
        ..createdAt = DateTime.now()
        ..samplingIntervalSeconds = samplingIntervalSeconds
        ..values = series;
      await _isar.collection<TimeSeriesData>().put(dataset);

      final metrics = OUMetrics()
        ..datasetName = name
        ..theta = result.theta
        ..mu = result.mu
        ..sigma = result.sigma
        ..halfLife = result.halfLife
        ..numObservations = result.numObservations
        ..rSquared = result.rSquared
        ..residualStd = result.residualStd
        ..logLikelihood = result.logLikelihood
        ..samplingIntervalSeconds = samplingIntervalSeconds
        ..method = result.method
        ..estimatedAt = DateTime.now();
      metrics.dataset.value = dataset;
      await _isar.collection<OUMetrics>().put(metrics);
      await metrics.dataset.save();
    });
  }

  Future<List<OUMetrics>> loadAll() async {
    final all =
        await _isar.collection<OUMetrics>().where().findAll();
    // Eagerly load dataset links (needed for series values in history tap).
    for (final m in all) {
      await m.dataset.load();
    }
    all.sort((a, b) => b.estimatedAt.compareTo(a.estimatedAt));
    return all;
  }

  Future<void> rename(int id, String newName) async {
    await _isar.writeTxn(() async {
      final metrics =
          await _isar.collection<OUMetrics>().get(id);
      if (metrics == null) return;
      metrics.datasetName = newName;
      await _isar.collection<OUMetrics>().put(metrics);

      await metrics.dataset.load();
      final ds = metrics.dataset.value;
      if (ds != null) {
        ds.name = newName;
        await _isar.collection<TimeSeriesData>().put(ds);
      }
    });
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      final metrics =
          await _isar.collection<OUMetrics>().get(id);
      if (metrics == null) return;

      await metrics.dataset.load();
      final ds = metrics.dataset.value;

      await _isar.collection<OUMetrics>().delete(id);
      if (ds != null) {
        await _isar.collection<TimeSeriesData>().delete(ds.id);
      }
    });
  }
}
```

- [ ] **Step 4: Run all tests**

```bash
fvm flutter test
```

Expected: all tests pass (controller tests catch repo errors silently — still fine).

- [ ] **Step 5: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/ou_metrics.dart lib/data/models/ou_metrics.g.dart \
        lib/data/repositories/estimation_repository.dart
git commit -m "feat: persist fit diagnostics in OUMetrics; add loadAll/rename/delete"
```

---

### Task 6: Estimation depth UI

**Files:**
- Modify: `lib/providers/providers.dart` — add `mlEstimatorProvider`, `selectedTabProvider`, `seriesTextProvider`
- Modify: `lib/ui/estimation/estimation_state.dart` — add `method`, `samplingIntervalSeconds`
- Modify: `lib/ui/estimation/estimation_controller.dart` — add `setMethod`, `loadFromHistory`; route OLS/MLE
- Modify: `lib/ui/estimation/widgets/input_panel.dart` — OLS|MLE `SegmentedButton`; `seriesTextProvider` sync
- Create: `lib/ui/estimation/widgets/diagnostics_panel.dart`
- Modify: `lib/ui/estimation/estimation_screen.dart` — show `DiagnosticsPanel`
- Create: `test/ui/diagnostics_panel_test.dart`

**Interfaces:**
- Consumes: `EstimationMethod` (Task 1), `MLEEstimator` (Task 4), extended `OUResult` (Task 2)
- Produces: `selectedTabProvider`, `seriesTextProvider` — consumed by Tasks 8 and 9

- [ ] **Step 1: Write failing widget test for `DiagnosticsPanel`**

```dart
// test/ui/diagnostics_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';
import 'package:ou_estimator/ui/estimation/widgets/diagnostics_panel.dart';
import 'package:ou_estimator/ui/core/theme.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

const _result = OUResult(
  theta: 0.35,
  mu: 10.0,
  sigma: 0.58,
  halfLife: 1.98,
  rSquared: 0.97,
  residualStd: 0.12,
  logLikelihood: -45.2,
  numObservations: 499,
  method: EstimationMethod.ols,
);

void main() {
  testWidgets('DiagnosticsPanel renders four metric cards', (tester) async {
    await tester.pumpWidget(_wrap(const DiagnosticsPanel(result: _result)));
    expect(find.text('R²'), findsOneWidget);
    expect(find.text('s'), findsOneWidget);
    expect(find.text('ln L'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('DiagnosticsPanel shows correct rSquared value', (tester) async {
    await tester.pumpWidget(_wrap(const DiagnosticsPanel(result: _result)));
    expect(find.text('0.9700'), findsOneWidget);
  });
}
```

Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` at top.

- [ ] **Step 2: Run to confirm failure**

```bash
fvm flutter test test/ui/diagnostics_panel_test.dart
```

Expected: `Cannot find 'DiagnosticsPanel'`.

- [ ] **Step 3: Create `DiagnosticsPanel`**

```dart
// lib/ui/estimation/widgets/diagnostics_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/use_cases/ou_estimator.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/glass_card.dart';

/// Four fit-diagnostic glass cards: R², s, ln L, N.
/// Pure presentation — state comes from [result].
class DiagnosticsPanel extends StatelessWidget {
  const DiagnosticsPanel({super.key, required this.result});

  final OUResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric('R²', 'Goodness of Fit', result.rSquared.toStringAsFixed(4), ''),
      _Metric('s', 'Residual Std', result.residualStd.toStringAsFixed(4), ''),
      _Metric('ln L', 'Log-Likelihood', result.logLikelihood.toStringAsFixed(2), ''),
      _Metric('N', 'Observations', result.numObservations.toString(), 'pairs'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.85,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (var i = 0; i < items.length; i++)
          _DiagnosticCard(metric: items[i], index: i),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.symbol, this.label, this.value, this.unit);
  final String symbol;
  final String label;
  final String value;
  final String unit;
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.metric, required this.index});

  final _Metric metric;
  final int index;

  static final TextStyle _symbolStyle = AppTheme.mono(
    color: AppTheme.accent,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _labelStyle = AppTheme.sans(
    color: AppTheme.textSecondary,
    fontSize: 12,
  );
  static final TextStyle _valueStyle = AppTheme.mono(
    color: AppTheme.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle _unitStyle = AppTheme.sans(
    color: AppTheme.textSecondary,
    fontSize: 11,
  );

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Semantics(
        label: '${metric.label}: ${metric.value} ${metric.unit}'.trim(),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(metric.symbol, style: _symbolStyle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric.label,
                      style: _labelStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(metric.value, style: _valueStyle),
              if (metric.unit.isNotEmpty)
                Text(metric.unit, style: _unitStyle),
            ],
          ),
        ),
      ),
    );

    return card
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: Motion.slow, curve: Motion.curve)
        .slideY(begin: 0.1, end: 0, duration: Motion.slow, curve: Motion.curve);
  }
}
```

- [ ] **Step 4: Update providers**

Replace `lib/providers/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../data/repositories/estimation_repository.dart';
import '../data/services/file_import_service.dart';
import '../data/services/text_input_parser.dart';
import '../domain/use_cases/mle_estimator.dart';
import '../domain/use_cases/ou_estimator.dart';
import '../ui/estimation/estimation_controller.dart';
import '../ui/estimation/estimation_state.dart';

/// App-wide Isar instance. Overridden in [main] after the async open.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in ProviderScope');
});

final textInputParserProvider =
    Provider<TextInputParser>((ref) => const TextInputParser());

final fileImportServiceProvider =
    Provider<FileImportService>((ref) => const FileImportService());

final ouEstimatorProvider = Provider<OUEstimator>((ref) => OUEstimator());

final mlEstimatorProvider =
    Provider<MLEEstimator>((ref) => MLEEstimator());

final estimationRepositoryProvider = Provider<EstimationRepository>((ref) {
  return EstimationRepository(ref.watch(isarProvider));
});

final estimationControllerProvider =
    NotifierProvider<EstimationController, EstimationState>(
  EstimationController.new,
);

/// Index of the currently selected tab in [AppShell].
/// Written by [HistoryScreen] after loading a run to navigate back to Estimation.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// One-shot text to load into [InputPanel]'s series [TextField].
/// [EstimationController.loadFromHistory] writes the joined series; [InputPanel]
/// consumes it via [ref.listen] and resets it to empty after applying.
final seriesTextProvider = StateProvider<String>((ref) => '');
```

- [ ] **Step 5: Update `EstimationState`**

Replace `lib/ui/estimation/estimation_state.dart`:

```dart
import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/estimation_method.dart';

/// Immutable snapshot of the estimation screen.
class EstimationState {
  const EstimationState({
    this.series = const [],
    this.result,
    this.error,
    this.loading = false,
    this.unitLabel = 'step',
    this.method = EstimationMethod.ols,
    this.samplingIntervalSeconds,
  });

  final List<double> series;
  final OUResult? result;
  final String? error;
  final bool loading;
  final String unitLabel;
  final EstimationMethod method;
  final double? samplingIntervalSeconds;

  bool get hasResult => result != null;

  EstimationState copyWith({
    List<double>? series,
    OUResult? result,
    String? error,
    bool? loading,
    String? unitLabel,
    EstimationMethod? method,
    double? samplingIntervalSeconds,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return EstimationState(
      series: series ?? this.series,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
      unitLabel: unitLabel ?? this.unitLabel,
      method: method ?? this.method,
      samplingIntervalSeconds:
          samplingIntervalSeconds ?? this.samplingIntervalSeconds,
    );
  }
}
```

- [ ] **Step 6: Update `EstimationController`**

Replace `lib/ui/estimation/estimation_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/mle_estimator.dart';
import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/dt_unit.dart';
import '../../domain/value/estimation_method.dart';
import '../../providers/providers.dart';
import 'estimation_state.dart';

class EstimationController extends Notifier<EstimationState> {
  @override
  EstimationState build() => const EstimationState();

  void setMethod(EstimationMethod method) {
    state = state.copyWith(method: method, clearResult: true, clearError: true);
  }

  /// Loads a series from history into state so the user can re-run estimation.
  /// Also writes the joined series text to [seriesTextProvider] so [InputPanel]
  /// can update its [TextField].
  void loadFromHistory(
      List<double> series, double samplingIntervalSeconds) {
    // Pick closest DtUnit by samplingIntervalSeconds.
    DtUnit bestUnit = DtUnit.steps;
    var bestDelta = double.infinity;
    for (final u in DtUnit.values) {
      if (u == DtUnit.steps) continue;
      final delta = (u.secondsPerUnit - samplingIntervalSeconds).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestUnit = u;
      }
    }
    final label = bestUnit == DtUnit.steps ? 'step' : bestUnit.label;

    ref.read(seriesTextProvider.notifier).state = series.join('\n');
    state = EstimationState(
      series: series,
      unitLabel: label,
      method: state.method,
      samplingIntervalSeconds: samplingIntervalSeconds,
    );
  }

  Future<void> compute(
    String raw, {
    double dt = 1.0,
    DtUnit unit = DtUnit.steps,
  }) async {
    final parser = ref.read(textInputParserProvider);
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
      result = state.method == EstimationMethod.mle
          ? ref.read(mlEstimatorProvider).estimate(series, dt: dt)
          : ref.read(ouEstimatorProvider).estimate(series, dt: dt);
    } on InsufficientDataException catch (e) {
      state = state.copyWith(
          loading: false, error: e.message, clearResult: true);
      return;
    } on NonStationaryException catch (e) {
      state = state.copyWith(
          loading: false, error: e.message, clearResult: true);
      return;
    }

    final dtSecs = dt * unit.secondsPerUnit;
    state = state.copyWith(
      series: series,
      result: result,
      unitLabel: unit.label,
      samplingIntervalSeconds: dtSecs,
      loading: false,
      clearError: true,
    );

    try {
      final repo = ref.read(estimationRepositoryProvider);
      await repo.save(
        name: 'session-${DateTime.now().millisecondsSinceEpoch}',
        series: series,
        samplingIntervalSeconds: dtSecs,
        result: result,
      );
    } catch (_) {
      // Persistence failure must not hide a valid result.
    }
  }

  void clear() => state = const EstimationState();
}
```

- [ ] **Step 7: Update `InputPanel` (add SegmentedButton + seriesTextProvider sync)**

In `lib/ui/estimation/widgets/input_panel.dart`, make these changes:

Add import near the top (after existing imports):
```dart
import '../../../domain/value/estimation_method.dart';
```

In `_InputPanelState.build()`, add `ref.listen` call after the existing `state` and `notifier` reads, before the `return Column(`:

```dart
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);

    // Sync TextField when a history run is loaded.
    ref.listen<String>(seriesTextProvider, (_, next) {
      if (next.isNotEmpty && _seriesController.text != next) {
        _seriesController.text = next;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(seriesTextProvider.notifier).state = '';
          }
        });
      }
    });

    return Column(
```

Add the `SegmentedButton` widget inside the `Column`, just before the `OutlinedButton.icon` (file import button). Insert after the Δt row's `const SizedBox(height: Spacing.lg)`:

```dart
        const SizedBox(height: Spacing.lg),
        // OLS / MLE method toggle
        SegmentedButton<EstimationMethod>(
          segments: const [
            ButtonSegment(
              value: EstimationMethod.ols,
              label: Text('OLS'),
            ),
            ButtonSegment(
              value: EstimationMethod.mle,
              label: Text('MLE'),
            ),
          ],
          selected: {state.method},
          onSelectionChanged: (selection) =>
              notifier.setMethod(selection.first),
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton.icon(
```

Remove the old `const SizedBox(height: Spacing.lg),` that was directly before `OutlinedButton.icon` to avoid duplicate spacing.

- [ ] **Step 8: Update `EstimationScreen._buildResults()` to show `DiagnosticsPanel`**

In `lib/ui/estimation/estimation_screen.dart`, add import:
```dart
import 'widgets/diagnostics_panel.dart';
```

In `_buildResults()`, after `MetricsPanel(...)` and its following `SizedBox`:
```dart
          MetricsPanel(result: state.result!, unitLabel: state.unitLabel),
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Fit diagnostics'),
          const SizedBox(height: Spacing.md),
          DiagnosticsPanel(result: state.result!),
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Series & equilibrium (μ)'),
```

- [ ] **Step 9: Run all tests**

```bash
fvm flutter test
```

Expected: all tests pass. `estimation_state_test.dart` passes because `method` has a default. `estimation_controller_test.dart` passes because the catch-all on repo is preserved.

- [ ] **Step 10: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 11: Commit**

```bash
git add lib/providers/providers.dart \
        lib/ui/estimation/estimation_state.dart \
        lib/ui/estimation/estimation_controller.dart \
        lib/ui/estimation/widgets/input_panel.dart \
        lib/ui/estimation/widgets/diagnostics_panel.dart \
        lib/ui/estimation/estimation_screen.dart \
        test/ui/diagnostics_panel_test.dart
git commit -m "feat: estimation depth UI — OLS/MLE toggle, DiagnosticsPanel"
```

---

## Sub-project #4 — History UI

---

### Task 7: `AppShell` navigation lift + `loadFromHistory` wiring

**Files:**
- Modify: `lib/ui/shell/app_shell.dart` — `ConsumerWidget` watching `selectedTabProvider`

**Interfaces:**
- Consumes: `selectedTabProvider` (Task 6)
- Produces: `AppShell` responds to programmatic tab switches from `HistoryScreen`

- [ ] **Step 1: Replace `AppShell` with `ConsumerWidget`**

Replace `lib/ui/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../core/tokens.dart';
import 'destinations.dart';

/// Adaptive navigation scaffold. Selected tab is driven by [selectedTabProvider]
/// so child screens (e.g. HistoryScreen) can switch tabs programmatically.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedTabProvider);
    void select(int i) =>
        ref.read(selectedTabProvider.notifier).state = i;

    final body = IndexedStack(
      index: index,
      children: [for (final d in appDestinations) d.builder(context)],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.useRail(constraints.maxWidth)) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in appDestinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: select,
            destinations: [
              for (final d in appDestinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Add `historyProvider` to providers**

In `lib/providers/providers.dart`, add at the bottom:

```dart
import '../data/models/ou_metrics.dart';

/// Loads all saved estimation runs, newest-first.
/// Invalidated by HistoryScreen after rename or delete.
final historyProvider = FutureProvider.autoDispose<List<OUMetrics>>((ref) {
  final repo = ref.watch(estimationRepositoryProvider);
  return repo.loadAll();
});
```

Add the import of `OUMetrics` at the top of `providers.dart` alongside the existing imports.

- [ ] **Step 3: Run all tests**

```bash
fvm flutter test
```

Expected: all tests pass. `AppShell` widget tests that look for `NavigationBar` or `NavigationRail` destinations should still pass since the logic is identical — only the state source changed.

- [ ] **Step 4: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/ui/shell/app_shell.dart lib/providers/providers.dart
git commit -m "feat: lift AppShell tab index to selectedTabProvider; add historyProvider"
```

---

### Task 8: `HistoryScreen` + `HistoryRunCard`

**Files:**
- Create: `lib/ui/history/widgets/history_run_card.dart`
- Modify: `lib/ui/history/history_screen.dart`
- Create: `test/ui/history_run_card_test.dart`

**Interfaces:**
- Consumes: `historyProvider`, `selectedTabProvider`, `estimationControllerProvider`, `estimationRepositoryProvider` (all prior tasks)
- Produces: `HistoryScreen` — complete list with load/rename/delete actions

- [ ] **Step 1: Write failing widget tests**

```dart
// test/ui/history_run_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/models/ou_metrics.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';
import 'package:ou_estimator/providers/providers.dart';
import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/history/history_screen.dart';

Widget _wrapWithOverride({required Widget child}) {
  final fakeMetrics = OUMetrics()
    ..id = 1
    ..datasetName = 'TestRun'
    ..theta = 0.35
    ..mu = 10.0
    ..sigma = 0.58
    ..halfLife = 1.98
    ..numObservations = 99
    ..rSquared = 0.97
    ..method = EstimationMethod.ols
    ..estimatedAt = DateTime(2026, 6, 29);

  return ProviderScope(
    overrides: [
      historyProvider.overrideWith((_) async => [fakeMetrics]),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

void main() {
  testWidgets('shows seeded run name in list', (tester) async {
    await tester.pumpWidget(_wrapWithOverride(child: const HistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('TestRun'), findsOneWidget);
  });

  testWidgets('shows method badge', (tester) async {
    await tester.pumpWidget(_wrapWithOverride(child: const HistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('OLS'), findsOneWidget);
  });

  testWidgets('empty state shows fallback text when list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [historyProvider.overrideWith((_) async => [])],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved runs appear here'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
fvm flutter test test/ui/history_run_card_test.dart
```

Expected: `Cannot find 'HistoryScreen'` or the test finds the placeholder text `Saved runs appear here` but not `TestRun`.

- [ ] **Step 3: Create `HistoryRunCard`**

```dart
// lib/ui/history/widgets/history_run_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ou_metrics.dart';
import '../../../data/repositories/estimation_repository.dart';
import '../../../domain/value/estimation_method.dart';
import '../../../providers/providers.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// One item in the history list. Tapping loads the series back into
/// the estimation screen.
class HistoryRunCard extends ConsumerWidget {
  const HistoryRunCard({super.key, required this.metrics});

  final OUMetrics metrics;

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(estimationRepositoryProvider);

    Future<void> handleTap() {
      final ds = metrics.dataset.value;
      if (ds == null) return Future.value();
      ref
          .read(estimationControllerProvider.notifier)
          .loadFromHistory(ds.values, ds.samplingIntervalSeconds);
      ref.read(selectedTabProvider.notifier).state = 0;
      return Future.value();
    }

    Future<void> handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete run?'),
          content: Text('Delete "${metrics.datasetName}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.delete(metrics.id);
        ref.invalidate(historyProvider);
      }
    }

    Future<void> handleRename() async {
      final controller =
          TextEditingController(text: metrics.datasetName);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename run'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        ),
      );
      if (newName != null &&
          newName.isNotEmpty &&
          newName != metrics.datasetName) {
        await repo.rename(metrics.id, newName);
        ref.invalidate(historyProvider);
      }
    }

    final methodBadgeColor = metrics.method == EstimationMethod.mle
        ? AppTheme.accent
        : AppTheme.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs),
      child: ListTile(
        onTap: handleTap,
        title: Text(
          metrics.datasetName,
          style: AppTheme.sans(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'θ=${metrics.theta.toStringAsFixed(3)}  '
          't½=${metrics.halfLife.toStringAsFixed(2)}  '
          '${_relativeTime(metrics.estimatedAt)}',
          style: AppTheme.sans(color: AppTheme.textSecondary, fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: methodBadgeColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            metrics.method.name.toUpperCase(),
            style: AppTheme.mono(
                color: methodBadgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline, size: 18),
              tooltip: 'Rename',
              onPressed: handleRename,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete',
              onPressed: handleDelete,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Replace `HistoryScreen`**

Replace `lib/ui/history/history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import 'widgets/history_run_card.dart';

/// Shows all saved estimation runs. Tapping a run loads it back into
/// the estimator screen.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load history: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 56,
                      color: AppTheme.textPrimary.withValues(alpha: 0.18)),
                  const SizedBox(height: Spacing.md),
                  Text('Saved runs appear here',
                      style: AppTheme.sans(
                          color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            itemCount: runs.length,
            itemBuilder: (_, i) => HistoryRunCard(metrics: runs[i]),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests**

```bash
fvm flutter test test/ui/history_run_card_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Run full suite**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/ui/history/history_screen.dart \
        lib/ui/history/widgets/history_run_card.dart \
        test/ui/history_run_card_test.dart
git commit -m "feat: history UI — list with load/rename/delete"
```

---

## Sub-project #5 — Export / Share

---

### Task 9: `ExportService` + `share_plus` dependency

**Files:**
- Modify: `pubspec.yaml` — add `share_plus`
- Create: `lib/data/services/export_service.dart`
- Create: `test/export_service_test.dart`

**Interfaces:**
- Consumes: `OUResult` (Task 2), `OUMetrics` (Task 5)
- Produces: `ExportService.resultToJson(OUResult, String, double) → String`, `.metricsToJson(OUMetrics) → String`, `.share(String, {required String runName}) → Future<void>`

- [ ] **Step 1: Write failing tests**

```dart
// test/export_service_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/models/ou_metrics.dart';
import 'package:ou_estimator/data/services/export_service.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';

const _result = OUResult(
  theta: 0.35,
  mu: 10.0,
  sigma: 0.58,
  halfLife: 1.98,
  rSquared: 0.97,
  residualStd: 0.12,
  logLikelihood: -45.2,
  numObservations: 99,
  method: EstimationMethod.ols,
);

void main() {
  final svc = const ExportService();

  group('resultToJson', () {
    late Map<String, dynamic> json;
    setUp(() {
      json = jsonDecode(
          svc.resultToJson(_result, 'test-run', 86400.0))
          as Map<String, dynamic>;
    });

    test('contains name', () => expect(json['name'], 'test-run'));
    test('contains method', () => expect(json['method'], 'ols'));
    test('contains samplingIntervalSeconds',
        () => expect(json['samplingIntervalSeconds'], 86400.0));
    test('parameters block has theta',
        () => expect((json['parameters'] as Map)['theta'], 0.35));
    test('diagnostics block has rSquared',
        () => expect((json['diagnostics'] as Map)['rSquared'], 0.97));
    test('diagnostics block has n',
        () => expect((json['diagnostics'] as Map)['n'], 99));
  });

  group('metricsToJson', () {
    late Map<String, dynamic> json;
    setUp(() {
      final m = OUMetrics()
        ..datasetName = 'hist-run'
        ..theta = 0.35
        ..mu = 10.0
        ..sigma = 0.58
        ..halfLife = 1.98
        ..rSquared = 0.97
        ..residualStd = 0.12
        ..logLikelihood = -45.2
        ..numObservations = 99
        ..samplingIntervalSeconds = 86400.0
        ..method = EstimationMethod.ols
        ..estimatedAt = DateTime(2026, 6, 29);
      json = jsonDecode(svc.metricsToJson(m)) as Map<String, dynamic>;
    });

    test('contains name', () => expect(json['name'], 'hist-run'));
    test('parameters block has theta',
        () => expect((json['parameters'] as Map)['theta'], 0.35));
    test('samplingIntervalSeconds persisted',
        () => expect(json['samplingIntervalSeconds'], 86400.0));
  });
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
fvm flutter test test/export_service_test.dart
```

Expected: `Cannot find 'ExportService'`.

- [ ] **Step 3: Add `share_plus` to `pubspec.yaml`**

In `pubspec.yaml`, under `dependencies:`, add:
```yaml
    share_plus: ^10.0.0
```

Then run:
```bash
fvm flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 4: Implement `ExportService`**

```dart
// lib/data/services/export_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../models/ou_metrics.dart';

/// Serializes O-U results to JSON and triggers the native share sheet.
class ExportService {
  const ExportService();

  String resultToJson(
    OUResult result,
    String name,
    double samplingIntervalSeconds,
  ) {
    return const JsonEncoder.withIndent('  ').convert({
      'name': name,
      'method': result.method.name,
      'estimatedAt': DateTime.now().toUtc().toIso8601String(),
      'samplingIntervalSeconds': samplingIntervalSeconds,
      'parameters': {
        'theta': result.theta,
        'mu': result.mu,
        'sigma': result.sigma,
        'halfLife': result.halfLife,
      },
      'diagnostics': {
        'rSquared': result.rSquared,
        'residualStd': result.residualStd,
        'logLikelihood': result.logLikelihood,
        'n': result.numObservations,
      },
    });
  }

  String metricsToJson(OUMetrics metrics) {
    return const JsonEncoder.withIndent('  ').convert({
      'name': metrics.datasetName,
      'method': metrics.method.name,
      'estimatedAt': metrics.estimatedAt.toUtc().toIso8601String(),
      'samplingIntervalSeconds': metrics.samplingIntervalSeconds,
      'parameters': {
        'theta': metrics.theta,
        'mu': metrics.mu,
        'sigma': metrics.sigma,
        'halfLife': metrics.halfLife,
      },
      'diagnostics': {
        'rSquared': metrics.rSquared,
        'residualStd': metrics.residualStd,
        'logLikelihood': metrics.logLikelihood,
        'n': metrics.numObservations,
      },
    });
  }

  /// Writes [json] to a temp file and opens the OS share sheet.
  Future<void> share(String json, {required String runName}) async {
    final dir = await getTemporaryDirectory();
    final safeName = runName.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'OU Estimate: $runName',
    );
  }
}
```

- [ ] **Step 5: Run tests**

```bash
fvm flutter test test/export_service_test.dart
```

Expected: 9 tests pass. (`share()` is not tested — it invokes platform channels not available in unit tests.)

- [ ] **Step 6: Run full suite**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock \
        lib/data/services/export_service.dart \
        test/export_service_test.dart
git commit -m "feat: ExportService — JSON serialization + share_plus integration"
```

---

### Task 10: Export UI (share buttons)

**Files:**
- Modify: `lib/providers/providers.dart` — add `exportServiceProvider`
- Modify: `lib/ui/estimation/estimation_screen.dart` — share button in results area
- Modify: `lib/ui/history/widgets/history_run_card.dart` — share icon in trailing row

**Interfaces:**
- Consumes: `ExportService` (Task 9), `EstimationState.samplingIntervalSeconds` (Task 6), `OUMetrics` (Task 5)

- [ ] **Step 1: Add `exportServiceProvider` to `providers.dart`**

In `lib/providers/providers.dart`, add import and provider:

```dart
import '../data/services/export_service.dart';

final exportServiceProvider =
    Provider<ExportService>((ref) => const ExportService());
```

- [ ] **Step 2: Add share button to `EstimationScreen`**

In `lib/ui/estimation/estimation_screen.dart`, modify `_buildResults()`:

After `_Legend()` widget (at the bottom of the results column), add:

```dart
          const SizedBox(height: Spacing.md),
          const _Legend(),
          const SizedBox(height: Spacing.md),
          _ShareButton(state: state),
```

Add this widget class at the bottom of the file (before the closing `}`):

```dart
class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.state});

  final EstimationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.hasResult) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text('Export JSON'),
        onPressed: () async {
          final svc = ref.read(exportServiceProvider);
          final name = 'ou-${DateTime.now().millisecondsSinceEpoch}';
          final json = svc.resultToJson(
            state.result!,
            name,
            state.samplingIntervalSeconds ?? 0.0,
          );
          await svc.share(json, runName: name);
        },
      ),
    );
  }
}
```

Make `EstimationScreen` (and `_EstimationScreenState`) pass `state` to `_ShareButton` in `_buildResults`. The method already receives `state` as a parameter — just add `_ShareButton(state: state)` at the bottom of the results column.

Also add `import '../../providers/providers.dart';` if not already imported (check — it's already there via the Riverpod ref usage). Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` if `ConsumerWidget` isn't already available (it should be since `EstimationScreen` is a `ConsumerStatefulWidget`).

- [ ] **Step 3: Add share button to `HistoryRunCard`**

In `lib/ui/history/widgets/history_run_card.dart`, in the `trailing: Row(...)`, add a share button before the rename button:

```dart
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 18),
              tooltip: 'Export JSON',
              onPressed: () async {
                final svc = ref.read(exportServiceProvider);
                final json = svc.metricsToJson(metrics);
                await svc.share(json, runName: metrics.datasetName);
              },
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline, size: 18),
              tooltip: 'Rename',
              onPressed: handleRename,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete',
              onPressed: handleDelete,
            ),
          ],
        ),
```

- [ ] **Step 4: Run all tests**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Analyze**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/providers/providers.dart \
        lib/ui/estimation/estimation_screen.dart \
        lib/ui/history/widgets/history_run_card.dart
git commit -m "feat: export/share buttons in estimation screen and history list"
```

---

## Verification

After all 10 tasks:

1. **Full test suite green:**
   ```bash
   fvm flutter test
   ```
   Expected: all tests pass (≥ 24 total: 14 existing widget + new unit tests).

2. **Zero analyzer warnings:**
   ```bash
   fvm flutter analyze
   ```
   Expected: `No issues found!`

3. **Manual — estimation depth:**
   - Launch app, paste a price series, toggle OLS → MLE, tap Compute
   - Verify `MetricsPanel` shows θ, μ, σ, t½
   - Verify `DiagnosticsPanel` shows R², s, ln L, N
   - Verify method badge changes between OLS / MLE

4. **Manual — history:**
   - Compute a run; switch to History tab
   - Verify run appears with method badge, θ, t½, relative timestamp
   - Tap run → series loads into Estimation tab input field
   - Rename a run; verify name updates in list
   - Delete a run (confirm dialog); verify it disappears

5. **Manual — export/share:**
   - After computing, tap "Export JSON" → OS share sheet opens with `.json` attachment
   - In History tab, tap share icon on a card → share sheet opens
   - Open shared JSON and verify schema: `name`, `method`, `parameters`, `diagnostics`
