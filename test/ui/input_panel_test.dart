import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/widgets/input_panel.dart';

Future<void> _pump(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SingleChildScrollView(child: InputPanel())),
      ),
    ),
  );
}

FilledButton _computeButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Compute'));

void main() {
  testWidgets('valid seed series enables Compute', (tester) async {
    await _pump(tester);
    expect(_computeButton(tester).onPressed, isNotNull);
  });

  testWidgets('unparseable input disables Compute', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('series-input')), 'abc def');
    await tester.pump();
    expect(_computeButton(tester).onPressed, isNull);
  });

  testWidgets('fewer than 3 points disables Compute', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('series-input')), '1\n2');
    await tester.pump();
    expect(_computeButton(tester).onPressed, isNull);
  });

  testWidgets('has a Δt value field and a unit dropdown', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('dt-value-input')), findsOneWidget);
    expect(find.byType(DropdownButton<DtUnitOption>), findsOneWidget);
  });
}
