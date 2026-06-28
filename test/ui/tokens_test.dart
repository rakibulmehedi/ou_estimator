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
