import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/value/dt_unit.dart';
import 'package:ou_estimator/providers/providers.dart';

void main() {
  test('compute parses, estimates, and records the unit label', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    // Mean-reverting series (estimated AR(1) b ≈ 0.51, in (0,1)); the old
    // zig-zag seed had b < 0 and the estimator (correctly) throws on it.
    await notifier.compute(
      '11.2\n10.51\n10.37\n10.32\n10.02\n10.19\n9.91\n9.89\n9.74\n9.67\n9.84\n10.1',
      dt: 1.0,
      unit: DtUnit.days,
    );

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isTrue);
    expect(state.unitLabel, 'day');
    expect(state.error, isNull);
  });

  test('compute surfaces a parse error and produces no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    await notifier.compute('not numbers');

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isFalse);
    expect(state.error, isNotNull);
  });
}
