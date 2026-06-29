import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ou_estimator/domain/value/dt_unit.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';
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

  test('setMethod switches method and clears prior result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    await notifier.compute(
      '11.2\n10.51\n10.37\n10.32\n10.02\n10.19\n9.91\n9.89\n9.74\n9.67',
      dt: 1.0,
    );
    expect(container.read(estimationControllerProvider).hasResult, isTrue);

    notifier.setMethod(EstimationMethod.mle);

    final state = container.read(estimationControllerProvider);
    expect(state.method, EstimationMethod.mle);
    expect(state.hasResult, isFalse);
    expect(state.error, isNull);
  });

  test('clear resets state to initial', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    await notifier.compute(
      '11.2\n10.51\n10.37\n10.32\n10.02\n10.19\n9.91\n9.89\n9.74\n9.67',
      dt: 1.0,
    );
    expect(container.read(estimationControllerProvider).hasResult, isTrue);

    notifier.clear();

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isFalse);
    expect(state.series, isEmpty);
    expect(state.error, isNull);
  });

  test('loadFromHistory maps 86400 s to day unit label', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    const series = [10.0, 10.5, 11.0, 10.8];
    notifier.loadFromHistory(series, 86400.0);

    final state = container.read(estimationControllerProvider);
    expect(state.series, series);
    expect(state.unitLabel, 'day');
    expect(state.samplingIntervalSeconds, 86400.0);
  });

  test('loadFromHistory maps 3600 s to hour unit label', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    notifier.loadFromHistory([1.0, 2.0, 3.0], 3600.0);

    expect(
      container.read(estimationControllerProvider).unitLabel,
      'hour',
    );
  });

  test('compute with MLE method produces result with method=mle', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    notifier.setMethod(EstimationMethod.mle);
    await notifier.compute(
      '11.2\n10.51\n10.37\n10.32\n10.02\n10.19\n9.91\n9.89\n9.74\n9.67\n9.84\n10.1',
      dt: 1.0,
    );

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isTrue);
    expect(state.result!.method, EstimationMethod.mle);
    expect(state.error, isNull);
  });

  test('compute surfaces InsufficientDataException for series shorter than 3', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    await notifier.compute('1\n2'); // only 2 points

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isFalse);
    expect(state.error, isNotNull);
  });

  test('compute surfaces NonStationaryException for an explosive series', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(estimationControllerProvider.notifier);

    // Doubling series → AR(1) b ≈ 2, which is ≥ 1 (non-stationary).
    await notifier.compute('1\n2\n4\n8\n16\n32');

    final state = container.read(estimationControllerProvider);
    expect(state.hasResult, isFalse);
    expect(state.error, isNotNull);
  });
}
