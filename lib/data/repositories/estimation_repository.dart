import 'package:isar_community/isar.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../models/ou_metrics.dart';
import '../models/time_series_data.dart';

/// Persists a dataset and its estimation result.
class EstimationRepository {
  EstimationRepository(this._isar);

  final Isar _isar;

  Future<void> save({
    required String name,
    required List<double> series,
    double samplingIntervalSeconds = 0.0,
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
        ..numObservations = result.numObservations
        ..rSquared = result.rSquared
        ..residualStd = result.residualStd
        ..logLikelihood = result.logLikelihood
        ..samplingIntervalSeconds = samplingIntervalSeconds
        ..method = result.method
        ..estimatedAt = DateTime.now();
      metrics.dataset.value = dataset;
      await _isar.collection<OUMetrics>().put(metrics);
      await metrics.dataset.save();
    });
  }

  Future<List<OUMetrics>> loadAll() async {
    final all = await _isar.collection<OUMetrics>().where().findAll();
    for (final m in all) {
      await m.dataset.load();
    }
    all.sort((a, b) => b.estimatedAt.compareTo(a.estimatedAt));
    return all;
  }

  Future<void> rename(int id, String newName) async {
    await _isar.writeTxn(() async {
      final metrics = await _isar.collection<OUMetrics>().get(id);
      if (metrics == null) return;
      metrics.datasetName = newName;
      await _isar.collection<OUMetrics>().put(metrics);

      await metrics.dataset.load();
      final ds = metrics.dataset.value;
      if (ds != null) {
        ds.name = newName;
        await _isar.collection<TimeSeriesData>().put(ds);
      }
    });
  }

  Future<void> delete(int id) async {
    final metrics = await _isar.collection<OUMetrics>().get(id);
    if (metrics == null) return;
    await metrics.dataset.load();
    final dsId = metrics.dataset.value?.id;

    await _isar.writeTxn(() async {
      await _isar.collection<OUMetrics>().delete(id);
      if (dsId != null) {
        await _isar.collection<TimeSeriesData>().delete(dsId);
      }
    });
  }
}
