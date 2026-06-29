import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/use_cases/ou_estimator.dart';
import '../models/ou_metrics.dart';

/// Serializes O-U results to JSON and triggers the native share sheet.
class ExportService {
  const ExportService();

  String resultToJson(
    OUResult result,
    String name,
    double samplingIntervalSeconds,
  ) {
    return const JsonEncoder.withIndent('  ').convert({
      'name': name,
      'method': result.method.name,
      'estimatedAt': DateTime.now().toUtc().toIso8601String(),
      'samplingIntervalSeconds': samplingIntervalSeconds,
      'parameters': {
        'theta': result.theta,
        'mu': result.mu,
        'sigma': result.sigma,
        'halfLife': result.halfLife,
      },
      'diagnostics': {
        'rSquared': result.rSquared,
        'residualStd': result.residualStd,
        'logLikelihood': result.logLikelihood,
        'n': result.numObservations,
      },
    });
  }

  String metricsToJson(OUMetrics metrics) {
    return const JsonEncoder.withIndent('  ').convert({
      'name': metrics.datasetName,
      'method': metrics.method.name,
      'estimatedAt': metrics.estimatedAt.toUtc().toIso8601String(),
      'samplingIntervalSeconds': metrics.samplingIntervalSeconds,
      'parameters': {
        'theta': metrics.theta,
        'mu': metrics.mu,
        'sigma': metrics.sigma,
        'halfLife': metrics.halfLife,
      },
      'diagnostics': {
        'rSquared': metrics.rSquared,
        'residualStd': metrics.residualStd,
        'logLikelihood': metrics.logLikelihood,
        'n': metrics.numObservations,
      },
    });
  }

  /// Writes [json] to a temp file and opens the OS share sheet.
  Future<void> share(String json, {required String runName}) async {
    final dir = await getTemporaryDirectory();
    final safeName = runName.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${dir.path}/$safeName.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'OU Estimate: $runName',
    );
  }
}
