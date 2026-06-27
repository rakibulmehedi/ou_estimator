import 'package:isar_community/isar.dart';

import 'time_series_data.dart';

part 'ou_metrics.g.dart';

/// Estimation method. `mle` reserved for a future enhancement.
enum EstimationMethod { ols, mle }

/// One stored estimation result for a dataset.
@collection
class OUMetrics {
  Id id = Isar.autoIncrement;

  /// Denormalized for fast lookup without traversing the link.
  @Index()
  late String datasetName;

  late double theta; // mean-reversion speed
  late double mu; // long-run / equilibrium mean
  late double sigma; // volatility
  late double halfLife; // ln(2) / theta
  late int numObservations; // N

  @enumerated
  late EstimationMethod method;

  late DateTime estimatedAt;

  final dataset = IsarLink<TimeSeriesData>();
}
