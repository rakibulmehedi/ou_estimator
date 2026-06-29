import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/models/ou_metrics.dart';
import 'package:ou_estimator/data/services/export_service.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';

const _result = OUResult(
  theta: 0.35,
  mu: 10.0,
  sigma: 0.58,
  halfLife: 1.98,
  rSquared: 0.97,
  residualStd: 0.12,
  logLikelihood: -45.2,
  numObservations: 99,
  method: EstimationMethod.ols,
);

void main() {
  const svc = ExportService();

  group('resultToJson', () {
    late Map<String, dynamic> json;
    setUp(() {
      json = jsonDecode(
        svc.resultToJson(_result, 'test-run', 86400.0),
      ) as Map<String, dynamic>;
    });

    test('contains name', () => expect(json['name'], 'test-run'));
    test('contains method', () => expect(json['method'], 'ols'));
    test('contains samplingIntervalSeconds',
        () => expect(json['samplingIntervalSeconds'], 86400.0));
    test('parameters block has theta',
        () => expect((json['parameters'] as Map)['theta'], 0.35));
    test('diagnostics block has rSquared',
        () => expect((json['diagnostics'] as Map)['rSquared'], 0.97));
    test('diagnostics block has n',
        () => expect((json['diagnostics'] as Map)['n'], 99));
  });

  group('metricsToJson', () {
    late Map<String, dynamic> json;
    setUp(() {
      final m = OUMetrics()
        ..datasetName = 'hist-run'
        ..theta = 0.35
        ..mu = 10.0
        ..sigma = 0.58
        ..halfLife = 1.98
        ..rSquared = 0.97
        ..residualStd = 0.12
        ..logLikelihood = -45.2
        ..numObservations = 99
        ..samplingIntervalSeconds = 86400.0
        ..method = EstimationMethod.ols
        ..estimatedAt = DateTime(2026, 6, 29);
      json = jsonDecode(svc.metricsToJson(m)) as Map<String, dynamic>;
    });

    test('contains name', () => expect(json['name'], 'hist-run'));
    test('parameters block has theta',
        () => expect((json['parameters'] as Map)['theta'], 0.35));
    test('samplingIntervalSeconds persisted',
        () => expect(json['samplingIntervalSeconds'], 86400.0));
  });
}
