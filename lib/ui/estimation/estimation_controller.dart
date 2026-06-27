import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../../providers/providers.dart';
import 'estimation_state.dart';

/// Drives the estimation screen: parse → estimate → display → persist.
///
/// The compute path (parse + OLS) is synchronous and fast, so a plain
/// [Notifier] with a `loading` flag is cleaner than wrapping the math in an
/// `AsyncNotifier`. Persistence runs best-effort afterwards.
class EstimationController extends Notifier<EstimationState> {
  @override
  EstimationState build() => const EstimationState();

  Future<void> compute(String raw) async {
    final parser = ref.read(textInputParserProvider);
    final estimator = ref.read(ouEstimatorProvider);

    state = state.copyWith(loading: true, clearError: true);

    final List<double> series;
    final OUResult result;
    try {
      series = parser.parse(raw);
      result = estimator.estimate(series);
    } on FormatException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
        clearResult: true,
      );
      return;
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
      loading: false,
      clearError: true,
    );

    // Persist best-effort — a storage failure must not hide a valid result.
    try {
      final repo = ref.read(estimationRepositoryProvider);
      await repo.save(
        name: 'session-${DateTime.now().millisecondsSinceEpoch}',
        series: series,
        samplingIntervalSeconds: 1.0,
        result: result,
      );
    } catch (_) {
      // Out of scope for UI feedback in Phase 3.
    }
  }

  void clear() => state = const EstimationState();
}
