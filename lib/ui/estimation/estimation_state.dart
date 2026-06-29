import '../../domain/use_cases/ou_estimator.dart';
import '../../domain/value/estimation_method.dart';

/// Immutable snapshot of the estimation screen.
class EstimationState {
  const EstimationState({
    this.series = const [],
    this.result,
    this.error,
    this.loading = false,
    this.unitLabel = 'step',
    this.method = EstimationMethod.ols,
    this.samplingIntervalSeconds,
  });

  final List<double> series;
  final OUResult? result;
  final String? error;
  final bool loading;

  /// Singular Δt unit label (e.g. 'day') for θ ("per <label>") and half-life.
  final String unitLabel;
  final EstimationMethod method;
  final double? samplingIntervalSeconds;

  bool get hasResult => result != null;

  EstimationState copyWith({
    List<double>? series,
    OUResult? result,
    String? error,
    bool? loading,
    String? unitLabel,
    EstimationMethod? method,
    double? samplingIntervalSeconds,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return EstimationState(
      series: series ?? this.series,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
      unitLabel: unitLabel ?? this.unitLabel,
      method: method ?? this.method,
      samplingIntervalSeconds:
          samplingIntervalSeconds ?? this.samplingIntervalSeconds,
    );
  }
}
