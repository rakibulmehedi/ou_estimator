import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/data/services/text_input_parser.dart';
import 'package:ou_estimator/ui/estimation/widgets/validation_summary.dart';

Future<void> _pump(WidgetTester tester, ParseResult result) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ValidationSummary(result: result))),
  );
}

void main() {
  testWidgets('error result shows the error message', (tester) async {
    await _pump(tester,
        const ParseResult(values: [], error: 'Enter a price series to begin.'));
    expect(find.textContaining('Enter a price series'), findsOneWidget);
  });

  testWidgets('valid result shows the point count', (tester) async {
    await _pump(tester, const ParseResult(values: [1, 2, 3]));
    expect(find.textContaining('3 points'), findsOneWidget);
  });

  testWidgets('warning result shows the warning text', (tester) async {
    await _pump(tester,
        const ParseResult(values: [1, 2, 3], warning: 'thousands separator?'));
    expect(find.textContaining('thousands separator'), findsOneWidget);
  });
}
