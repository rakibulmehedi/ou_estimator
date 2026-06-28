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
