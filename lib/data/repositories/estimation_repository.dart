import 'package:isar_community/isar.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../models/ou_metrics.dart';
import '../models/time_series_data.dart';

/// Persists a dataset and its estimation result as the single source of truth.
class EstimationRepository {
  EstimationRepository(this._isar);

  final Isar _isar;

  Future<void> save({
    required String name,
    required List<double> series,
    required double samplingIntervalSeconds,
    required OUResult result,
  }) async {
    await _isar.writeTxn(() async {
      final dataset = TimeSeriesData()
        ..name = name
        ..createdAt = DateTime.now()
        ..samplingIntervalSeconds = samplingIntervalSeconds
        ..values = series;
      await _isar.collection<TimeSeriesData>().put(dataset);

      final metrics = OUMetrics()
        ..datasetName = name
        ..theta = result.theta
        ..mu = result.mu
        ..sigma = result.sigma
        ..halfLife = result.halfLife
        ..numObservations = series.length
        ..method = EstimationMethod.ols
        ..estimatedAt = DateTime.now();
      metrics.dataset.value = dataset;
      await _isar.collection<OUMetrics>().put(metrics);
      await metrics.dataset.save();
    });
  }
}
