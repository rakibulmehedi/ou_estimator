import 'package:isar_community/isar.dart';

import 'ou_metrics.dart';

part 'time_series_data.g.dart';

/// One stored dataset = one uniformly-sampled price series.
@collection
class TimeSeriesData {
  Id id = Isar.autoIncrement;

  /// Dataset identifier. Unique + replace-on-conflict keeps the DB clean.
  @Index(unique: true, replace: true)
  late String name;

  late DateTime createdAt;

  /// Uniform sampling step Δt in seconds (locked: uniform Δt only).
  late double samplingIntervalSeconds;

  /// Observation values in chronological order.
  late List<double> values;

  /// Estimation runs computed from this dataset.
  @Backlink(to: 'dataset')
  final metrics = IsarLinks<OUMetrics>();
}
