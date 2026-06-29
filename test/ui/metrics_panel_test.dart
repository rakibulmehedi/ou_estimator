import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/widgets/metrics_panel.dart';

void main() {
  testWidgets('renders the unit label on θ and half-life', (tester) async {
    const result =
        OUResult(theta: 0.3, mu: 10.0, sigma: 0.5, halfLife: 2.3);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: MetricsPanel(result: result, unitLabel: 'day'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1)); // let entrance settle
    expect(find.text('per day'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);
  });
}
