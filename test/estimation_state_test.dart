import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/ui/estimation/estimation_state.dart';

void main() {
  test('unitLabel defaults to "step"', () {
    expect(const EstimationState().unitLabel, 'step');
  });

  test('copyWith updates unitLabel and preserves it when omitted', () {
    final a = const EstimationState().copyWith(unitLabel: 'day');
    expect(a.unitLabel, 'day');
    final b = a.copyWith(loading: true);
    expect(b.unitLabel, 'day');
  });
}
