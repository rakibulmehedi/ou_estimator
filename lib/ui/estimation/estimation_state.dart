import '../../domain/use_cases/ou_estimator.dart';

/// Immutable snapshot of the estimation screen.
class EstimationState {
  const EstimationState({
    this.series = const [],
    this.result,
    this.error,
    this.loading = false,
  });

  final List<double> series;
  final OUResult? result;
  final String? error;
  final bool loading;

  bool get hasResult => result != null;

  EstimationState copyWith({
    List<double>? series,
    OUResult? result,
    String? error,
    bool? loading,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return EstimationState(
      series: series ?? this.series,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      loading: loading ?? this.loading,
    );
  }
}
