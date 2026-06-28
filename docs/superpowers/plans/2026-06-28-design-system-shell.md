# Design System Foundation + Adaptive Nav Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Systematize the existing Phase-4 dark theme into reusable tokens + shared components and wrap the app in an adaptive navigation shell, without touching domain/data/providers.

**Architecture:** Add a pure-const `tokens.dart` (spacing/radii/motion/breakpoints), extract the frosted card and section caption into shared widgets, and introduce an `AppShell` that swaps `NavigationBar` (compact) for `NavigationRail` (medium/expanded) and renders the estimation screen as two-pane master/detail at expanded width. All estimation logic and providers are reused unchanged.

**Tech Stack:** Flutter (Material 3), Riverpod (existing, untouched), `google_fonts`, `flutter_animate`, `fl_chart` — all already in `pubspec.yaml`. No new dependencies.

## Global Constraints

- **UI layer only.** No edits to `lib/domain/`, `lib/data/`, `lib/providers/`, `estimation_controller.dart`, or `estimation_state.dart`.
- **No new dependencies.** Use only packages already in `pubspec.yaml`.
- **No new providers / no new estimation state.** Shell selection is local widget state.
- **Reuse the existing palette** in `lib/ui/core/theme.dart` (`AppTheme`): background `#0D1117`, accent `#4F8CFF`, glass tokens, etc. Do not change color values.
- **Breakpoints (verbatim):** compact `< 600`, medium `600–839`, expanded `>= 840`. Rail shows at `>= 600`; two-pane shows at `>= 840`.
- **Test runner:** `flutter test` (use `fvm flutter test` if the toolchain is fvm-managed, as in prior phases). All existing tests must stay green.
- **Existing tests that must not break:** `test/ou_estimator_test.dart`, `test/text_input_parser_test.dart` (do not touch). `test/widget_test.dart` is updated in Task 5.

---

### Task 0: Repository prep (git init)

The working directory is not a git repository yet; later tasks commit per step. Initialize it once.

**Files:**
- Uses existing `.gitignore` (already present).

- [ ] **Step 1: Initialize the repo**

Run:
```bash
git init
git add -A
git commit -m "chore: snapshot existing app before design-system upgrade"
```
Expected: a single initial commit containing the current source tree.

- [ ] **Step 2: Confirm clean tree**

Run: `git status`
Expected: `nothing to commit, working tree clean`.

---

### Task 1: Design tokens

**Files:**
- Create: `lib/ui/core/tokens.dart`
- Test: `test/ui/tokens_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class Spacing` — `static const double xs=4, sm=8, md=12, lg=16, xl=24, xxl=32;`
  - `class Radii` — `static const double sm=8, md=12, lg=16;`
  - `class Motion` — `static const Duration fast=Duration(milliseconds:150), base=Duration(milliseconds:250), slow=Duration(milliseconds:400); static const Curve curve=Curves.easeOutCubic;`
  - `class Breakpoints` — `static const double medium=600, expanded=840; static bool isCompact(double w); static bool useRail(double w); static bool isTwoPane(double w);`

- [ ] **Step 1: Write the failing test**

`test/ui/tokens_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/ui/core/tokens.dart';

void main() {
  group('Breakpoints', () {
    test('classifies compact widths (< 600)', () {
      expect(Breakpoints.isCompact(400), isTrue);
      expect(Breakpoints.useRail(400), isFalse);
      expect(Breakpoints.isTwoPane(400), isFalse);
    });

    test('medium width (600-839): rail, single pane', () {
      expect(Breakpoints.isCompact(700), isFalse);
      expect(Breakpoints.useRail(700), isTrue);
      expect(Breakpoints.isTwoPane(700), isFalse);
    });

    test('expanded width (>= 840): rail and two-pane', () {
      expect(Breakpoints.useRail(1000), isTrue);
      expect(Breakpoints.isTwoPane(1000), isTrue);
    });

    test('boundaries are inclusive at the lower edge', () {
      expect(Breakpoints.useRail(600), isTrue);
      expect(Breakpoints.isTwoPane(840), isTrue);
      expect(Breakpoints.isTwoPane(839), isFalse);
    });
  });

  test('scales expose ascending positive values', () {
    expect(Spacing.xs < Spacing.lg, isTrue);
    expect(Radii.sm < Radii.lg, isTrue);
    expect(Motion.fast < Motion.slow, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/tokens_test.dart`
Expected: FAIL — `tokens.dart` / `Breakpoints` not found.

- [ ] **Step 3: Write the implementation**

`lib/ui/core/tokens.dart`:
```dart
import 'package:flutter/material.dart';

/// Layout + motion design tokens. Pure const — single source of truth for
/// spacing, corner radii, animation timing, and responsive breakpoints.
/// Color tokens live in [AppTheme] (lib/ui/core/theme.dart).
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class Radii {
  Radii._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve curve = Curves.easeOutCubic;
}

/// Responsive width breakpoints. Rail appears at [medium]+, the two-pane
/// master/detail layout appears at [expanded]+.
class Breakpoints {
  Breakpoints._();
  static const double medium = 600;
  static const double expanded = 840;

  static bool isCompact(double width) => width < medium;
  static bool useRail(double width) => width >= medium;
  static bool isTwoPane(double width) => width >= expanded;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/tokens_test.dart`
Expected: PASS (all cases).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/tokens.dart test/ui/tokens_test.dart
git commit -m "feat: add design tokens (spacing, radii, motion, breakpoints)"
```

---

### Task 2: GlassCard shared widget

Extract the frosted-glass surface currently inlined in `metrics_panel.dart` into one reusable widget.

**Files:**
- Create: `lib/ui/core/widgets/glass_card.dart`
- Test: `test/ui/glass_card_test.dart`

**Interfaces:**
- Consumes: `AppTheme.glassFill`, `AppTheme.glassBorder`, `AppTheme.glassBlur` (existing); `Radii.lg`.
- Produces: `class GlassCard extends StatelessWidget { const GlassCard({super.key, required Widget child, EdgeInsetsGeometry? padding}); }`

- [ ] **Step 1: Write the failing test**

`test/ui/glass_card_test.dart`:
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/ui/core/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard renders its child inside a blur layer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            padding: EdgeInsets.all(16),
            child: Text('hello'),
          ),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/glass_card_test.dart`
Expected: FAIL — `glass_card.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/ui/core/widgets/glass_card.dart`:
```dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Frosted-glass surface: a translucent fill over a backdrop blur with a
/// hairline border. Pure presentation — wrap any [child]. Holds no state.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.glassBlur,
            sigmaY: AppTheme.glassBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.glassFill,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/glass_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/widgets/glass_card.dart test/ui/glass_card_test.dart
git commit -m "feat: extract reusable GlassCard widget"
```

---

### Task 3: SectionLabel shared widget

Replace the repeated `labelLarge` + `Colors.white70` captions with one widget.

**Files:**
- Create: `lib/ui/core/widgets/section_label.dart`
- Test: `test/ui/section_label_test.dart`

**Interfaces:**
- Consumes: `AppTheme.sans`, `AppTheme.textSecondary`.
- Produces: `class SectionLabel extends StatelessWidget { const SectionLabel(String text, {super.key}); }`

- [ ] **Step 1: Write the failing test**

`test/ui/section_label_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/ui/core/widgets/section_label.dart';

void main() {
  testWidgets('SectionLabel renders the given text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionLabel('Price series')),
      ),
    );
    expect(find.text('Price series'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/section_label_test.dart`
Expected: FAIL — `section_label.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/ui/core/widgets/section_label.dart`:
```dart
import 'package:flutter/material.dart';

import '../theme.dart';

/// Caption shown above an input field or content section. Centralizes the
/// muted-secondary label style used across screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.sans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/section_label_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/widgets/section_label.dart test/ui/section_label_test.dart
git commit -m "feat: add SectionLabel widget"
```

---

### Task 4: Adaptive AppShell + destinations + History placeholder

**Files:**
- Create: `lib/ui/shell/destinations.dart`
- Create: `lib/ui/shell/app_shell.dart`
- Create: `lib/ui/history/history_screen.dart`
- Test: `test/ui/app_shell_test.dart`

**Interfaces:**
- Consumes: `Breakpoints.useRail` (Task 1); existing `EstimationScreen`.
- Produces:
  - `class AppDestination { const AppDestination({required IconData icon, required IconData selectedIcon, required String label, required WidgetBuilder builder}); }`
  - `final List<AppDestination> appDestinations;` (top-level)
  - `class AppShell extends StatefulWidget { const AppShell({super.key}); }`
  - `class HistoryScreen extends StatelessWidget { const HistoryScreen({super.key}); }`

- [ ] **Step 1: Write the failing test**

`test/ui/app_shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/shell/app_shell.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: const AppShell()),
    ),
  );
}

void main() {
  testWidgets('compact width shows NavigationBar, not NavigationRail',
      (tester) async {
    await _pumpAt(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('expanded width shows NavigationRail, not NavigationBar',
      (tester) async {
    await _pumpAt(tester, const Size(1200, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('default destination is the estimator (Compute visible)',
      (tester) async {
    await _pumpAt(tester, const Size(400, 800));
    expect(find.text('Compute'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/app_shell_test.dart`
Expected: FAIL — `app_shell.dart` not found.

- [ ] **Step 3: Create the History placeholder**

`lib/ui/history/history_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tokens.dart';

/// Placeholder for sub-project #4 (saved-run history). Renders an honest
/// empty state so the shell has a real second destination without faking data.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 56, color: AppTheme.textPrimary.withValues(alpha: 0.18)),
            const SizedBox(height: Spacing.md),
            Text('Saved runs appear here',
                style: AppTheme.sans(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create the destinations list**

`lib/ui/shell/destinations.dart`:
```dart
import 'package:flutter/material.dart';

import '../estimation/estimation_screen.dart';
import '../history/history_screen.dart';

/// One navigation destination: its icons, label, and the screen it shows.
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;
}

/// App-wide destinations. Adding a screen = one entry here; the shell adapts.
/// Not `const`: the builder closures are not const-constructible.
final List<AppDestination> appDestinations = <AppDestination>[
  AppDestination(
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate,
    label: 'Estimator',
    builder: (_) => const EstimationScreen(),
  ),
  AppDestination(
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: 'History',
    builder: (_) => const HistoryScreen(),
  ),
];
```

- [ ] **Step 5: Create the AppShell**

`lib/ui/shell/app_shell.dart`:
```dart
import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'destinations.dart';

/// Adaptive navigation scaffold. Shows a [NavigationRail] at medium/expanded
/// widths and a [NavigationBar] at compact widths. Destinations are kept alive
/// via [IndexedStack] so each screen preserves its state across tab switches.
/// Selected index is local state — no provider.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _index,
      children: [for (final d in appDestinations) d.builder(context)],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.useRail(constraints.maxWidth)) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
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
            selectedIndex: _index,
            onDestinationSelected: _select,
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

> Note: `EstimationScreen` and `HistoryScreen` keep their own `Scaffold`/`AppBar`. Nesting them inside the shell's `Scaffold` is intentional and valid — the inner Scaffold supplies the per-screen AppBar, the outer one supplies the nav.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/ui/app_shell_test.dart`
Expected: PASS (all three cases).

- [ ] **Step 7: Commit**

```bash
git add lib/ui/shell/ lib/ui/history/ test/ui/app_shell_test.dart
git commit -m "feat: add adaptive AppShell with rail/bar and History placeholder"
```

---

### Task 5: Wire AppShell into the app + update smoke test

**Files:**
- Modify: `lib/main.dart` (the `home:` of `OUApp`)
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppShell` (Task 4).

- [ ] **Step 1: Update the smoke test to pump AppShell**

Replace the body of `test/widget_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/shell/app_shell.dart';

void main() {
  testWidgets('app shell renders the estimator with input and compute button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AppShell(),
        ),
      ),
    );

    expect(find.text('Compute'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS. (Default shell width in tests is large, but the estimator is destination 0 and visible regardless of rail/bar.)

- [ ] **Step 3: Point the app at AppShell**

In `lib/main.dart`, change the import and the `home:`.

Replace:
```dart
import 'ui/estimation/estimation_screen.dart';
```
with:
```dart
import 'ui/shell/app_shell.dart';
```

Replace:
```dart
      home: const EstimationScreen(),
```
with:
```dart
      home: const AppShell(),
```

- [ ] **Step 4: Verify the full suite still passes**

Run: `flutter test`
Expected: PASS — all existing math/parser tests plus the new UI tests.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat: mount AppShell as app home"
```

---

### Task 6: Responsive estimation screen + adopt shared components

Make `EstimationScreen` two-pane at expanded width and swap its inline styling for `SectionLabel`, `GlassCard`, and tokens. Also adopt tokens in `metrics_panel.dart` and `price_chart.dart`.

**Files:**
- Modify: `lib/ui/estimation/estimation_screen.dart`
- Modify: `lib/ui/estimation/widgets/metrics_panel.dart`
- Modify: `lib/ui/estimation/widgets/price_chart.dart`
- Test: `test/ui/estimation_layout_test.dart`

**Interfaces:**
- Consumes: `SectionLabel` (Task 3), `GlassCard` (Task 2), `Spacing`/`Radii`/`Motion`/`Breakpoints` (Task 1).
- Produces: no new public API (screen internals only).

- [ ] **Step 1: Write the failing layout test**

`test/ui/estimation_layout_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/estimation_screen.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: const EstimationScreen()),
    ),
  );
}

void main() {
  testWidgets('compact width: single-column (no two-pane Row key)',
      (tester) async {
    await _pumpAt(tester, const Size(400, 900));
    expect(find.byKey(const Key('estimation-two-pane')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Compute'), findsOneWidget);
  });

  testWidgets('expanded width: two-pane layout present', (tester) async {
    await _pumpAt(tester, const Size(1200, 900));
    expect(find.byKey(const Key('estimation-two-pane')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Compute'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/estimation_layout_test.dart`
Expected: FAIL — no widget with key `estimation-two-pane` at expanded width.

- [ ] **Step 3: Refactor `estimation_screen.dart` for responsive layout**

Replace the entire `build` method of `_EstimationScreenState` with the following, and add the two private builder methods. Keep the `Scaffold`/`AppBar`, the `_controller`, `dispose`, and the helper classes (`_ErrorBanner`, `_Legend`, `_EmptyHint`) as they are, except update imports and restyle as shown.

Update the imports at the top of the file to add:
```dart
import '../core/tokens.dart';
import '../core/widgets/section_label.dart';
```

New `build` + builders:
```dart
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('O–U Parameter Estimator'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoPane = Breakpoints.isTwoPane(constraints.maxWidth);
            if (twoPane) {
              return Row(
                key: const Key('estimation-two-pane'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: _buildInput(state, notifier),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: _buildResults(state),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInput(state, notifier),
                      _buildResults(state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInput(EstimationState state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Price series  ·  comma-separated, uniform Δt'),
        const SizedBox(height: Spacing.sm),
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(
            hintText: 'e.g. 10, 9.8, 10.2, 9.9, ...',
          ),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: state.loading
              ? null
              : () => notifier.compute(_controller.text),
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

  Widget _buildResults(EstimationState state) {
    if (state.hasResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricsPanel(result: state.result!),
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Series & equilibrium (μ)'),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 280,
            child: PriceChart(
              series: state.series,
              mu: state.result!.mu,
            ),
          ),
          const SizedBox(height: Spacing.md),
          const _Legend(),
        ],
      );
    }
    if (state.error == null) {
      return const Padding(
        padding: EdgeInsets.only(top: Spacing.xxl),
        child: _EmptyHint(),
      );
    }
    return const SizedBox.shrink();
  }
```

Also: at the top of the file the existing import of `EstimationState` type is implicit through the controller. Add this import so `_buildInput`/`_buildResults` can name `EstimationState`:
```dart
import 'estimation_state.dart';
```
(If `estimation_state.dart` exports the `EstimationState` type used by the provider; it does — it is the state class in `lib/ui/estimation/estimation_state.dart`.)

> The helper widgets `_ErrorBanner`, `_Legend`, `_EmptyHint` keep their current bodies. Optionally restyle their `Colors.white60/38` literals to `AppTheme.textSecondary/textTertiary`, but that is not required for tests to pass.

- [ ] **Step 4: Run the layout test to verify it passes**

Run: `flutter test test/ui/estimation_layout_test.dart`
Expected: PASS — `estimation-two-pane` present at 1200px, absent at 400px.

- [ ] **Step 5: Adopt GlassCard + tokens in `metrics_panel.dart`**

In `lib/ui/estimation/widgets/metrics_panel.dart`, replace the hand-built `RepaintBoundary → ClipRRect → BackdropFilter → Container` wrapper in `_MetricCard.build` with the shared `GlassCard`, and use motion tokens for the entrance.

Add imports:
```dart
import '../../core/widgets/glass_card.dart';
import '../../core/tokens.dart';
```
Remove the now-unused `import 'dart:ui';` only if no other `ImageFilter`/`FontFeature` use remains (the file uses `FontFeature` via `AppTheme.mono`, which lives in theme.dart, so `dart:ui` is no longer needed here — remove it).

Replace the `final card = RepaintBoundary( … );` assignment (the whole frosted wrapper) with:
```dart
    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Semantics(
        label: '${metric.label}: ${metric.value} ${metric.unit}',
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
              Text(metric.unit, style: _unitStyle),
            ],
          ),
        ),
      ),
    );
```
And replace the entrance animation tail:
```dart
    return card
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
```
with:
```dart
    return card
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: Motion.slow, curve: Motion.curve)
        .slideY(begin: 0.1, end: 0, duration: Motion.slow, curve: Motion.curve);
```

- [ ] **Step 6: Adopt tokens in `price_chart.dart`**

In `lib/ui/estimation/widgets/price_chart.dart`, add:
```dart
import '../../core/tokens.dart';
```
Replace the tooltip rounded radius literal `tooltipRoundedRadius: 8,` with `tooltipRoundedRadius: Radii.sm,`. Leave chart math and behavior unchanged.

- [ ] **Step 7: Run the full suite**

Run: `flutter test`
Expected: PASS — all tests green (math, parser, tokens, glass_card, section_label, app_shell, widget, estimation_layout).

- [ ] **Step 8: Commit**

```bash
git add lib/ui/estimation/ test/ui/estimation_layout_test.dart
git commit -m "feat: responsive two-pane estimation screen using shared components"
```

---

### Task 7: Final verification gate

**Files:** none (verification only).

- [ ] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: `No issues found!` (generated `*.g.dart` already excluded by `analysis_options.yaml`).

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all tests pass. Confirm the count increased by the new UI test files and no prior test regressed.

- [ ] **Step 3: Build smoke (macOS)**

Run: `flutter build macos --debug`
Expected: `✓ Built` (matches the platform proven in prior phases).

- [ ] **Step 4: Manual sanity (optional but recommended)**

Run the app on macOS, resize the window narrow→wide: bottom `NavigationBar` should become a side `NavigationRail` at ~600px, and the estimator should split into two panes at ~840px. Switch to History → empty-state placeholder shows.

- [ ] **Step 5: Commit any final fixes**

```bash
git add -A
git commit -m "chore: design-system shell verification pass"
```

---

## Self-Review

**Spec coverage:**
- Refine current dark / systematize → tokens (Task 1), GlassCard (Task 2), SectionLabel (Task 3), token adoption (Task 6). ✔
- Adaptive rail+bar shell → AppShell (Task 4). ✔
- Two-pane master/detail at expanded, single column below → Task 6. ✔
- Shell destinations Estimator + History placeholder → Task 4. ✔
- main.dart home → AppShell → Task 5. ✔
- Domain/data/providers untouched → Global Constraints; no task edits those paths. ✔
- Tests: update widget_test (Task 5), responsive tests (Tasks 4 & 6), gate analyze/test/build (Task 7). ✔
- No new deps → Global Constraints; all imports are existing packages. ✔

**Placeholder scan:** No "TBD/TODO/handle edge cases" — every code step shows full code. The History screen is an intentional product placeholder (empty state), not a plan placeholder. ✔

**Type consistency:** `Breakpoints.useRail/isTwoPane/isCompact`, `Spacing.*`, `Radii.lg/sm`, `Motion.slow/curve`, `GlassCard({child, padding})`, `SectionLabel(text)`, `AppDestination({icon, selectedIcon, label, builder})`, `appDestinations`, `AppShell`, `HistoryScreen` — names used in later tasks match their Task-1–4 definitions. ✔

**Note on `notifier` typing in Task 6:** `_buildInput` takes `dynamic notifier` to avoid importing the controller's concrete type into the screen (the screen already obtains it via `ref.read(...)`). This keeps the Global Constraint of not coupling to new provider types while staying within existing patterns.
