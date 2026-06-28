# Design System Foundation + Adaptive Nav Shell — Design Spec

**Date:** 2026-06-28
**Sub-project:** #1 of 5 (UX/aesthetic upgrade roadmap)
**Status:** Approved — ready for implementation plan

---

## Context

`ou_estimator` is a Flutter Ornstein–Uhlenbeck parameter estimator. A prior
"Phase 4" pass delivered a premium fintech-dark look (GitHub-style palette,
frosted-glass metric cards, bundled Inter + JetBrains Mono, `fl_chart`
visualization, `flutter_animate` entrances). The app is currently a single
screen (`EstimationScreen`).

A larger UX upgrade was scoped and decomposed into 5 independent sub-projects:

1. **Design system foundation + adaptive nav shell** ← this spec
2. Input subsystem (file import, smart paste-parse, Δt control, inline validation)
3. Estimation depth (real fit diagnostics R²/residual/logLik/N, MLE, OLS/MLE toggle)
4. History UI (saved-run list, reload, rename, delete)
5. Export / share

This spec covers **#1 only**. It is the foundation the later sub-projects render on.

## Goal & Constraints

Systematize the proven Phase-4 dark look into reusable tokens + shared
components, and wrap the app in an adaptive shell that future screens plug into.

**Hard constraints (carry the Phase-4 discipline):**

- **UI layer only.** Zero changes to `domain/`, `data/`, `providers/`, the
  estimation controller, or estimation state.
- Widgets stay pure consumers — no new providers, no new state coupling for the
  estimation flow.
- No new runtime dependencies (use what's in `pubspec.yaml` today).
- All existing tests stay green; the math/parser tests are untouched.

## Aesthetic Direction (locked)

Refine the current dark theme — do **not** redesign. Keep the palette in
`AppTheme` (background `#0D1117`, surface, accent `#4F8CFF`, glass tokens,
positive/negative). The work is *systematization*, not reinvention: a full
spacing scale, motion language, radii, and shared components so every current
and future screen is visually consistent.

## Navigation Shell (locked)

Adaptive: `NavigationBar` (bottom) on compact widths, `NavigationRail` (side)
on medium/expanded widths. One responsive shell, native-feeling on phone and
macOS.

## Wide-Screen Layout (locked)

Two-pane master/detail at expanded width: input + controls on the left pane,
results (metrics + chart) on the right pane. Single centered max-width column
below the expanded breakpoint.

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `lib/ui/core/tokens.dart` | Layout primitives — all pure const. `Spacing` (4/8/12/16/24/32), `Radii` (8/12/16), `Motion` (durations: fast 150ms, base 250ms, slow 400ms; curve `easeOutCubic`), `Breakpoints` (compact `<600`, medium `600–839`, expanded `>=840`). |
| `lib/ui/core/widgets/glass_card.dart` | Reusable frosted-glass card extracted from `metrics_panel` (`ClipRRect` + `BackdropFilter` + glass fill/border tokens + `RepaintBoundary`). Takes a child; holds no state. |
| `lib/ui/core/widgets/section_label.dart` | The "caption above a field/section" text style, replacing the duplicated `labelLarge` + `Colors.white70` usages in the screen. |
| `lib/ui/shell/destinations.dart` | Immutable destination list (icon, selected icon, label, screen builder). |
| `lib/ui/shell/app_shell.dart` | `AppShell` (`StatefulWidget`). `LayoutBuilder` selects `NavigationBar` (compact) vs `NavigationRail` (medium/expanded). `IndexedStack` over destinations preserves each screen's state. Selected index held in local `State` — no provider. |

### Modified files

| File | Change |
|------|--------|
| `main.dart` | `home: const AppShell()` instead of `EstimationScreen`. No other change. |
| `lib/ui/estimation/estimation_screen.dart` | Body becomes responsive. At `>=840`: two-pane `Row` (input/controls left, results right). Below: single centered column with capped max-width. Reuse `SectionLabel` + `GlassCard` + tokens; remove inline `Colors.white70` / `Colors.white38` / `Colors.white60` literals in favor of theme/token colors. Controller wiring unchanged. |
| `lib/ui/estimation/widgets/metrics_panel.dart` | Use the extracted `GlassCard` and `Motion`/`Spacing` tokens. Visual/animation behavior unchanged. |
| `lib/ui/estimation/widgets/price_chart.dart` | Adopt `Spacing`/`Radii` tokens where it currently hard-codes values. Chart behavior unchanged. |

### Shell destinations

- **Estimator** — the existing `EstimationScreen` (active, default).
- **History** — honest placeholder empty-state ("Saved runs appear here") until
  sub-project #4 wires real data. Keeps the shell genuine without faking data.

No Settings/About destination (YAGNI).

## Data Flow & Error Handling

- Estimation flow unchanged: `EstimationScreen` still reads
  `estimationControllerProvider` exactly as today.
- Shell selection is local widget state.
- Responsive switching via `LayoutBuilder` on available width.
- Existing error banner and empty-hint are retained, restyled through tokens.
- Responsive guards: layout reads constraints, no `MediaQuery` assumptions that
  break in tests.

## Component Boundaries

- `GlassCard` — *what:* frosted surface container. *Use:* wrap any content.
  *Depends on:* glass tokens only. Internals swappable without touching consumers.
- `SectionLabel` — *what:* caption text. *Use:* `SectionLabel('Price series …')`.
  *Depends on:* theme text style + token color.
- `AppShell` — *what:* adaptive nav scaffold. *Use:* app `home`. *Depends on:*
  `destinations.dart`. Adding a destination = one list entry; shell unchanged.
- `tokens.dart` — *what:* design constants. *Depends on:* nothing. Single source
  of truth for spacing/motion/breakpoints.

## Testing / Verification

- **Update** `test/widget_test.dart`: pump `AppShell`; assert `Compute` button
  and the series `TextField` are present on the default (Estimator) destination.
- **Add** responsive tests:
  - compact width (e.g. 400px) → `NavigationBar` present, `NavigationRail` absent.
  - expanded width (e.g. 1000px) → `NavigationRail` present, `NavigationBar` absent.
  - expanded width → two-pane layout present (both input field and, after a
    compute, results visible without scrolling between them).
- **Gate:** `flutter analyze` clean · `flutter test` green · `flutter build
  macos --debug` ✓.

## Out of Scope (later sub-projects)

- Δt / sampling-interval control, file import, smart paste-parse, inline
  validation — **#2**.
- Real fit diagnostics (R²/residualStd/logLikelihood/N — currently NOT computed;
  `OUEstimator` returns only θ/μ/σ/t½), MLE estimator, OLS/MLE toggle — **#3**.
- History data (list/reload/rename/delete) — **#4**.
- Export / share — **#5**.

The two-pane input pane is deliberately laid out to leave room for the #2 input
controls (Δt, validation) to slot in without re-architecting the screen.
