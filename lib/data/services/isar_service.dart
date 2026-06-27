import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ou_metrics.dart';
import '../models/time_series_data.dart';

/// Opens and holds the app-wide Isar instance. Stateless wrapper.
class IsarService {
  IsarService(this.db);

  final Isar db;

  /// Async-open both collections in the app documents directory.
  static Future<IsarService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [TimeSeriesDataSchema, OUMetricsSchema],
      directory: dir.path,
    );
    return IsarService(isar);
  }
}
