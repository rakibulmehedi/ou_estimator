# Contributing to ou_estimator

Thank you for your interest in contributing to **ou_estimator** — a Flutter app for
Ornstein-Uhlenbeck parameter estimation and mean reversion analysis.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Code Style](#code-style)
- [Running Tests](#running-tests)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

---

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you agree to uphold this standard. Please report unacceptable behavior
to rakibulislammehedi4@gmail.com.

---

## How to Contribute

1. **Check existing issues** — search [Issues](https://github.com/rakibulmehedi/ou_estimator/issues) before opening a new one.
2. **Fork the repository** and create a feature branch from `main`.
3. **Write tests** for any new logic. The project uses unit tests extensively (84 tests).
4. **Ensure all checks pass** before submitting.
5. **Open a pull request** against `main` with a clear description.

---

## Development Setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel, `>=3.4.0`)
- Dart SDK `>=3.4.0 <4.0.0` (included with Flutter)
- Android Studio or Xcode (for device targets)
- `make` (optional, for convenience commands)

### Setup Steps

```bash
# 1. Clone your fork
git clone https://github.com/<your-username>/ou_estimator.git
cd ou_estimator

# 2. Install dependencies
flutter pub get

# 3. Verify setup
flutter doctor
flutter analyze
flutter test
```

### Convenience Commands (Makefile)

```bash
make analyze   # Run flutter analyze
make test      # Run all unit tests with coverage
make build     # Build debug APK
```

---

## Project Structure

```
lib/
  core/           # Shared utilities, constants, theme
  features/
    estimation/   # OU parameter estimation logic (OLS + MLE)
    charts/       # fl_chart visualizations
    history/      # Isar persistence layer
  shared/         # Shared widgets and providers (Riverpod)
test/             # Unit tests mirroring lib/ structure
```

The core statistical logic lives in `lib/features/estimation/` — the
`OUEstimator` class implements both OLS and exact MLE parameter fitting.

---

## Code Style

This project uses standard Dart/Flutter conventions:

- **Formatter:** `dart format` (enforced in CI)
- **Linter:** `flutter analyze` with rules in `analysis_options.yaml`
- **Naming:** `lowerCamelCase` for variables/functions, `UpperCamelCase` for classes
- **Providers:** Riverpod `@riverpod` code generation style
- **No magic numbers** — use named constants in `lib/core/constants/`

Run before committing:

```bash
dart format .
flutter analyze
```

---

## Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a specific test file
flutter test test/features/estimation/ou_estimator_test.dart
```

The project targets **80%+ test coverage**. New features should include corresponding
unit tests. Statistical algorithms especially must be tested against known analytical
solutions.

---

## Submitting a Pull Request

1. Create a branch: `git checkout -b feat/your-feature-name`
2. Make your changes with atomic commits using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` — new feature
   - `fix:` — bug fix
   - `refactor:` — code restructure (no behavior change)
   - `test:` — tests only
   - `docs:` — documentation only
   - `chore:` — dependency updates, CI changes
3. Ensure `flutter analyze` and `flutter test` both pass
4. Push your branch and open a PR against `main`
5. Fill in the PR template completely

PRs that break existing tests or drop coverage will not be merged until addressed.

---

## Reporting Bugs

Use the [Bug Report template](https://github.com/rakibulmehedi/ou_estimator/issues/new?template=bug_report.yml).

Please include:
- App version (visible in the About screen)
- Device/OS (Android version or iOS version)
- Steps to reproduce
- Any input data (price series) that triggers the issue

---

## Requesting Features

Use the [Feature Request template](https://github.com/rakibulmehedi/ou_estimator/issues/new?template=feature_request.yml).

Good feature requests explain the **trading or analytical use case** being served,
not just the implementation detail.

---

## Questions?

Open a [Discussion](https://github.com/rakibulmehedi/ou_estimator/discussions) —
Issues are for bugs and confirmed feature requests only.
