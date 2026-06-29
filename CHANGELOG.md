# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- MLE estimator via exact O-U transition density (Nelder-Mead simplex, pure Dart)
- OLS/MLE toggle `SegmentedButton` in input panel
- Fit diagnostics panel: R², residual std, log-likelihood, observation count
- History screen: list of saved runs with method badge, θ, t½, relative timestamp
- History actions: tap to reload series into estimator, rename, delete
- Export/Share: JSON via native OS share sheet (`share_plus`)
- Share button on estimation screen results and each history run card
- `selectedTabProvider` — programmatic tab switching from History → Estimation
- `seriesTextProvider` — syncs `TextField` when loading a run from history
- `historyProvider` (`FutureProvider.autoDispose`) for reactive history list
- `loadAll()`, `rename()`, `delete()` on `EstimationRepository`
- Nullable diagnostic fields on `OUMetrics` (`rSquared`, `residualStd`, `logLikelihood`, `samplingIntervalSeconds`)
- `EstimationMethod` enum moved to domain layer (`lib/domain/value/estimation_method.dart`)

## [1.0.0] — 2026-06-28

### Added
- Ornstein-Uhlenbeck parameter estimation via discrete OLS (θ, μ, σ, half-life)
- Glass-morphic dark theme with entrance animations (`flutter_animate`)
- Time series chart with mean-reversion line (`fl_chart`)
- Local persistence via Isar community fork (Dart 3.12 compatible)
- Bundled offline fonts: Inter + JetBrains Mono (no first-paint FOUT)
- Unit tests: OLS math validation, text parser edge cases, UI smoke test (10/10 pass)
