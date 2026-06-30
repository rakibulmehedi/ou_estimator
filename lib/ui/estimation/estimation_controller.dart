import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/dt_unit.dart';
import '../../domain/value/estimation_method.dart';
import '../../providers/providers.dart';
import 'estimation_state.dart';

/// Drives the estimation screen: parse → estimate → display → persist.
class EstimationController extends Notifier<EstimationState> {
  @override
  EstimationState build() => const EstimationState();

  void setMethod(EstimationMethod method) {
    state = state.copyWith(method: method, clearResult: true, clearError: true);
  }

  /// Loads a series from history into state and pushes text to [seriesTextProvider]
  /// so [InputPanel] updates its TextField.
  void loadFromHistory(List<double> series, double samplingIntervalSeconds) {
    DtUnit bestUnit = DtUnit.steps;
    var bestDelta = double.infinity;
    for (final u in DtUnit.values) {
      if (u == DtUnit.steps) continue;
      final delta = (u.secondsPerUnit - samplingIntervalSeconds).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestUnit = u;
      }
    }
    final label = bestUnit.label;

    ref.read(seriesTextProvider.notifier).state = series.join('\n');
    state = EstimationState(
      series: series,
      unitLabel: label,
      method: state.method,
      samplingIntervalSeconds: samplingIntervalSeconds,
    );
  }

  Future<void> compute(
    String raw, {
    double dt = 1.0,
    DtUnit unit = DtUnit.steps,
  }) async {
    final parser = ref.read(textInputParserProvider);
    state = state.copyWith(loading: true, clearError: true);

    final parsed = parser.parse(raw);
    if (parsed.error != null) {
      state = state.copyWith(
        loading: false,
        error: parsed.error,
        clearResult: true,
      );
      return;
    }

    final series = parsed.values;
    final OUResult result;
    try {
      result = state.method == EstimationMethod.mle
          ? ref.read(mlEstimatorProvider).estimate(series, dt: dt)
          : ref.read(ouEstimatorProvider).estimate(series, dt: dt);
    } on InsufficientDataException catch (e) {
      state = state.copyWith(loading: false, error: e.message, clearResult: true);
      return;
    } on NonStationaryException catch (e) {
      state = state.copyWith(loading: false, error: e.message, clearResult: true);
      return;
    }

    final dtSecs = dt * unit.secondsPerUnit;
    state = state.copyWith(
      series: series,
      result: result,
      unitLabel: unit.label,
      samplingIntervalSeconds: dtSecs.toDouble(),
      loading: false,
      clearError: true,
    );

    try {
      final repo = ref.read(estimationRepositoryProvider);
      await repo.save(
        name: 'session-${DateTime.now().millisecondsSinceEpoch}',
        series: series,
        samplingIntervalSeconds: dtSecs.toDouble(),
        result: result,
      );
    } catch (_) {}
  }

  void clear() => state = const EstimationState();
}
