import 'package:isar_community/isar.dart';

import '../../domain/value/estimation_method.dart';
import 'time_series_data.dart';

part 'ou_metrics.g.dart';

/// One stored estimation result for a dataset.
@collection
class OUMetrics {
  Id id = Isar.autoIncrement;

  @Index()
  late String datasetName;

  late double theta;
  late double mu;
  late double sigma;
  late double halfLife;
  late int numObservations;

  @enumerated
  late EstimationMethod method;

  late DateTime estimatedAt;

  final dataset = IsarLink<TimeSeriesData>();
}
