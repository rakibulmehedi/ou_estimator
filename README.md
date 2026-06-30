# ou_estimator

Ornstein-Uhlenbeck parameter estimator for Flutter. Fits θ (mean reversion), μ (equilibrium), σ (volatility), and half-life from any uniformly-sampled price series — using OLS or exact MLE.

## Features

- **OLS estimator** — discrete AR(1) regression; instant
- **MLE estimator** — exact O-U transition density via pure-Dart Nelder-Mead simplex
- **Fit diagnostics** — R², residual std, log-likelihood, observation count
- **History** — saves every run to Isar; reload, rename, or delete from History tab
- **Export / Share** — JSON export via native OS share sheet (`share_plus`)
- **Glass-morphic dark theme** — Inter + JetBrains Mono, `flutter_animate` entrances
- **Adaptive layout** — `NavigationBar` (compact) / `NavigationRail` (wide)
- **File import** — CSV or plain-text series via `file_picker`

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter (via fvm) | `>=3.22` |
| Dart SDK | `>=3.4.0 <4.0.0` |
| fvm | any recent |

Install fvm: `dart pub global activate fvm`

### Setup

```bash
fvm flutter pub get
make codegen        # generates Isar schema (ou_metrics.g.dart, time_series_data.g.dart)
make run
```

<!-- AUTO-GENERATED from Makefile -->
## Commands

| Command | Description |
|---------|-------------|
| `make get` | `fvm flutter pub get` |
| `make analyze` | `fvm flutter analyze` |
| `make test` | `fvm flutter test` |
| `make coverage` | Run tests with coverage → open HTML report |
| `make build-debug` | Debug APK |
| `make build-aab` | Release Android App Bundle |
| `make build-release` | Release APKs split per ABI |
| `make clean` | `fvm flutter clean` |
| `make run` | `fvm flutter run` |
| `make codegen` | Regenerate Isar schema via `build_runner` |
<!-- END AUTO-GENERATED -->

## Architecture

```
lib/
├── domain/
│   ├── value/
│   │   ├── estimation_method.dart   EstimationMethod enum (ols | mle)
│   │   └── dt_unit.dart             Sampling interval units
│   └── use_cases/
│       ├── ou_estimator.dart        OLS estimator → OUResult
│       ├── mle_estimator.dart       MLE estimator (exact transition density)
│       └── nelder_mead.dart         Pure-Dart Nelder-Mead simplex optimizer
├── data/
│   ├── models/
│   │   ├── ou_metrics.dart          Isar @collection — stored estimation result
│   │   └── time_series_data.dart    Isar @collection — stored dataset
│   ├── repositories/
│   │   └── estimation_repository.dart  save / loadAll / rename / delete
│   └── services/
│       ├── export_service.dart      JSON serialization + share_plus
│       ├── file_import_service.dart CSV/TXT file picker
│       └── text_input_parser.dart   Inline series parser
├── providers/
│   └── providers.dart               All Riverpod providers
└── ui/
    ├── shell/                        AppShell — adaptive nav
    ├── estimation/                   Estimation screen + widgets
    ├── history/                      History screen + HistoryRunCard
    └── core/                         Theme, tokens, shared widgets
```

## State Management

Riverpod 2 throughout — `NotifierProvider` for the estimation controller, `FutureProvider.autoDispose` for history, `StateProvider` for tab index and series-text sync.

## Isar Schema

Two collections:

| Collection | Key fields |
|-----------|------------|
| `OUMetrics` | `theta`, `mu`, `sigma`, `halfLife`, `rSquared`, `residualStd`, `logLikelihood`, `numObservations`, `method`, `samplingIntervalSeconds` |
| `TimeSeriesData` | `name`, `values`, `samplingIntervalSeconds`, `createdAt` |

Linked via `IsarLink<TimeSeriesData>` on `OUMetrics`. Run `make codegen` after any schema change.

## Export JSON Schema

```json
{
  "version": 1,
  "name": "AAPL_daily",
  "method": "ols",
  "estimatedAt": "2026-06-30T00:00:00.000Z",
  "samplingIntervalSeconds": 86400.0,
  "parameters": { "theta": 0.338, "mu": 150.2, "sigma": 0.58, "halfLife": 2.05 },
  "diagnostics": { "rSquared": 0.97, "residualStd": 0.12, "logLikelihood": -45.2, "n": 251 }
}
```

## Testing

```bash
make test
```

<!-- AUTO-GENERATED from test/ -->
| Test file | Coverage |
|-----------|---------|
| `ou_estimator_test.dart` | OLS math, edge cases, diagnostics (R², s, logL, N) |
| `mle_estimator_test.dart` | MLE recovery, bounds, exceptions |
| `nelder_mead_test.dart` | 2D/3D quadratic minimization |
| `export_service_test.dart` | JSON shape validation |
| `estimation_controller_test.dart` | State transitions, error paths |
| `estimation_state_test.dart` | `copyWith` completeness |
| `text_input_parser_test.dart` | Comma/newline/mixed parsing |
| `dt_unit_test.dart` | Unit labels and secondsPerUnit |
| `ui/` (9 files) | Widget smoke tests, layout, glass cards |
<!-- END AUTO-GENERATED -->

84 tests, 0 failures.

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod ^2.5.1` | State management |
| `isar_community ^3.3.2` | Local persistence (Dart 3.12 fork) |
| `isar_community_flutter_libs ^3.3.2` | Isar native libraries (Android/iOS/macOS) |
| `path_provider ^2.1.4` | App directory access |
| `file_picker ^8.1.0` | CSV/TXT import |
| `fl_chart ^0.69.0` | Price + mean-reversion chart |
| `google_fonts ^6.2.1` | Inter + JetBrains Mono (bundled offline) |
| `flutter_animate ^4.5.0` | Entrance animations |
| `share_plus ^10.0.0` | Native OS share sheet |
