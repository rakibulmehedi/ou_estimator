import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/dt_unit.dart';
import '../../providers/providers.dart';
import 'estimation_state.dart';

/// Drives the estimation screen: parse → estimate → display → persist.
///
/// The compute path (parse + OLS) is synchronous and fast, so a plain
/// [Notifier] with a `loading` flag is cleaner than an `AsyncNotifier`.
/// Persistence runs best-effort afterwards.
class EstimationController extends Notifier<EstimationState> {
  @override
  EstimationState build() => const EstimationState();

  Future<void> compute(
    String raw, {
    double dt = 1.0,
    DtUnit unit = DtUnit.steps,
  }) async {
    final parser = ref.read(textInputParserProvider);
    final estimator = ref.read(ouEstimatorProvider);

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
      result = estimator.estimate(series, dt: dt);
    } on InsufficientDataException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
        clearResult: true,
      );
      return;
    } on NonStationaryException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
        clearResult: true,
      );
      return;
    }

    state = state.copyWith(
      series: series,
      result: result,
      unitLabel: unit.label,
      loading: false,
      clearError: true,
    );

    // Persist best-effort — a storage failure must not hide a valid result.
    try {
      final repo = ref.read(estimationRepositoryProvider);
      await repo.save(
        name: 'session-${DateTime.now().millisecondsSinceEpoch}',
        series: series,
        samplingIntervalSeconds: dt * unit.secondsPerUnit,
        result: result,
      );
    } catch (_) {
      // Out of scope for UI feedback here.
    }
  }

  void clear() => state = const EstimationState();
}
