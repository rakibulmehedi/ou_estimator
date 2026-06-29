import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../data/models/ou_metrics.dart';
import '../data/repositories/estimation_repository.dart';
import '../data/services/export_service.dart';
import '../data/services/file_import_service.dart';
import '../data/services/text_input_parser.dart';
import '../domain/use_cases/mle_estimator.dart';
import '../domain/use_cases/ou_estimator.dart';
import '../ui/estimation/estimation_controller.dart';
import '../ui/estimation/estimation_state.dart';

/// App-wide Isar instance. Overridden in [main] after the async open.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in ProviderScope');
});

final textInputParserProvider =
    Provider<TextInputParser>((ref) => const TextInputParser());

final fileImportServiceProvider =
    Provider<FileImportService>((ref) => const FileImportService());

final ouEstimatorProvider = Provider<OUEstimator>((ref) => OUEstimator());

final mlEstimatorProvider =
    Provider<MLEEstimator>((ref) => MLEEstimator());

final estimationRepositoryProvider = Provider<EstimationRepository>((ref) {
  return EstimationRepository(ref.watch(isarProvider));
});

final estimationControllerProvider =
    NotifierProvider<EstimationController, EstimationState>(
  EstimationController.new,
);

/// Index of the currently selected tab in AppShell.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// One-shot text to load into InputPanel's series TextField.
/// EstimationController.loadFromHistory writes joined series; InputPanel
/// consumes via ref.listen and resets to empty after applying.
final seriesTextProvider = StateProvider<String>((ref) => '');

final exportServiceProvider =
    Provider<ExportService>((ref) => const ExportService());

/// Loads all saved estimation runs, newest-first.
final historyProvider = FutureProvider.autoDispose<List<OUMetrics>>((ref) {
  final repo = ref.watch(estimationRepositoryProvider);
  return repo.loadAll();
});
