# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-06-30

### Added
- **MLE estimation**: choose between OLS (discrete AR(1)) and MLE (exact O-U transition density) via `SegmentedButton` toggle
- **Nelder-Mead simplex optimizer**: pure-Dart, dependency-free; powers MLE parameter search
- **Fit diagnostics panel**: R², residual std (σ̂), log-likelihood, observation count as glass cards with staggered entrance animation
- **Sampling interval control**: `DtUnit` enum (steps / seconds / minutes / hours / days / weeks); InputPanel Δt field + unit picker; all estimation paths scale to seconds internally
- **File import**: load CSV/TXT price series from device via `file_picker`; macOS sandbox entitlement included
- **InputPanel**: unified data-entry widget — text area, Δt controls, file-import button, live parse validation (`ValidationSummary`)
- **History screen**: paginated list of saved runs — method badge (OLS/MLE), θ, half-life, relative timestamp
- **History actions**: tap to reload series into estimator; inline rename and delete with confirmation dialog; JSON export/share per run
- **Export / Share**: `ExportService` serializes result or saved run to versioned JSON (`"version": 1`) and opens native OS share sheet via `share_plus`; share button on both estimation results and history cards
- `selectedTabProvider` — programmatic tab switching (History → Estimation after load)
- `seriesTextProvider` — syncs `TextField` when reloading a run from history
- `historyProvider` (`FutureProvider.autoDispose`) — reactive history list, auto-invalidated on mutation
- `loadAll()`, `rename()`, `delete()` on `EstimationRepository`
- Nullable diagnostic fields on `OUMetrics`: `rSquared`, `residualStd`, `logLikelihood`, `samplingIntervalSeconds`
- Custom launcher icon (generated via `flutter_launcher_icons`)

### Changed
- `TextInputParser` rewritten to return non-throwing `ParseResult` (value + optional error) instead of throwing
- `compute()` now accepts `dt` + `DtUnit`; persists `samplingIntervalSeconds` to `OUMetrics`
- `EstimationMethod` promoted to domain layer (`lib/domain/value/estimation_method.dart`) — decoupled from UI

### Fixed
- Share error handling: `try/catch` + `SnackBar` on estimation screen and history run card
- `_importFile` guarded against use-after-dispose with `mounted` check
- Android `compileSdk` override for `file_picker` — `afterEvaluate` registered before `evaluationDependsOn` so AGP DSL is not yet locked when override fires
- Dead ternary removed in `loadFromHistory` (`bestUnit` never equals `DtUnit.steps` post-loop)
- `DiagnosticsPanel` grid spacing uses `Spacing.md` token; card aspect ratio extracted to named constant
- `ExportService` injected via `exportServiceProvider` in history run card (was `const ExportService()`, bypassing DI)

## [1.0.0] — 2026-06-28

### Added
- Ornstein-Uhlenbeck parameter estimation via discrete OLS (θ, μ, σ, half-life)
- Glass-morphic dark theme with entrance animations (`flutter_animate`)
- Time series chart with mean-reversion line (`fl_chart`)
- Local persistence via Isar community fork (Dart 3.12 compatible)
- Bundled offline fonts: Inter + JetBrains Mono (no first-paint FOUT)
- Unit tests: OLS math validation, text parser edge cases, UI smoke test (10/10 pass)
