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
