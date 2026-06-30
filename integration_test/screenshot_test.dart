import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ou_estimator/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Screenshot 1: main input screen
    await binding.takeScreenshot('screen_input');

    // Enter price data
    final textField = find.byType(TextField).first;
    await tester.tap(textField);
    await tester.enterText(
      textField,
      '11.2,10.51,10.37,10.32,10.02,10.19,9.91,9.89,9.74,9.67,9.84,10.1,'
      '10.3,10.5,10.2,9.9,9.7,9.5,9.8,10.0,10.4,10.6,10.3,10.1,9.8,'
      '9.6,9.9,10.2,10.5,10.7',
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Tap Compute
    final computeBtn = find.text('Compute');
    if (computeBtn.evaluate().isNotEmpty) {
      await tester.tap(computeBtn);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // Screenshot 2: results
    await binding.takeScreenshot('screen_results');
  });
}
