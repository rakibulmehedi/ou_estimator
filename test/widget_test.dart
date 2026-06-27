import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/ui/core/theme.dart';
import 'package:ou_estimator/ui/estimation/estimation_screen.dart';

void main() {
  testWidgets('estimation screen renders input and compute button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EstimationScreen(),
        ),
      ),
    );

    expect(find.text('Compute'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
