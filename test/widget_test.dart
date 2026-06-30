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
    expect(find.byKey(const Key('series-input')), findsOneWidget);
  });
}
