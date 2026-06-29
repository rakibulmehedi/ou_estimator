import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';
import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/widgets/diagnostics_panel.dart';

const _result = OUResult(
  theta: 0.35,
  mu: 10.0,
  sigma: 0.58,
  halfLife: 1.98,
  rSquared: 0.9750,
  residualStd: 0.1234,
  logLikelihood: -45.21,
  numObservations: 99,
  method: EstimationMethod.ols,
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: DiagnosticsPanel(result: _result),
        ),
      ),
    ),
  );
  // Let entrance animations settle.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('renders four metric symbol labels', (tester) async {
    await _pump(tester);
    expect(find.text('R²'), findsOneWidget);
    expect(find.text('s'), findsOneWidget);
    expect(find.text('ln L'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('displays rSquared formatted to 4 decimal places', (tester) async {
    await _pump(tester);
    expect(find.text('0.9750'), findsOneWidget);
  });

  testWidgets('displays numObservations as integer string', (tester) async {
    await _pump(tester);
    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('shows "pairs" unit beneath the N card', (tester) async {
    await _pump(tester);
    expect(find.text('pairs'), findsOneWidget);
  });

  testWidgets('shows descriptive label text for each metric', (tester) async {
    await _pump(tester);
    expect(find.text('Goodness of Fit'), findsOneWidget);
    expect(find.text('Residual Std'), findsOneWidget);
    expect(find.text('Log-Likelihood'), findsOneWidget);
    expect(find.text('Observations'), findsOneWidget);
  });
}
