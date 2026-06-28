import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../data/repositories/estimation_repository.dart';
import '../data/services/file_import_service.dart';
import '../data/services/text_input_parser.dart';
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

final estimationRepositoryProvider = Provider<EstimationRepository>((ref) {
  return EstimationRepository(ref.watch(isarProvider));
});

final estimationControllerProvider =
    NotifierProvider<EstimationController, EstimationState>(
  EstimationController.new,
);
