import '../../domain/use_cases/ou_estimator.dart';

/// Immutable snapshot of the estimation screen.
class EstimationState {
  const EstimationState({
    this.series = const [],
    this.result,
    this.error,
    this.loading = false,
    this.unitLabel = 'step',
  });

  final List<double> series;
  final OUResult? result;
  final String? error;
  final bool loading;

  /// Singular unit label for the active Δt (e.g. 'day'); annotates θ / half-life.
  final String unitLabel;

  bool get hasResult => result != null;

  EstimationState copyWith({
    List<double>? series,
    OUResult? result,
    String? error,
    bool? loading,
    String? unitLabel,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return EstimationState(
      series: series ?? this.series,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
      unitLabel: unitLabel ?? this.unitLabel,
    );
  }
}
