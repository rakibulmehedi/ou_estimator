import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/mle_estimator.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';
import 'package:ou_estimator/domain/value/estimation_method.dart';

double _gauss(Random r) {
  final u1 = max(r.nextDouble(), 1e-12);
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * r.nextDouble());
}

List<double> _meanReverting({
  int n = 1000,
  double b = 0.7,
  double mu = 10.0,
  double noise = 0.5,
  int seed = 42,
}) {
  final r = Random(seed);
  final a = mu * (1 - b);
  final out = <double>[mu];
  for (var i = 1; i < n; i++) {
    out.add(a + b * out.last + noise * _gauss(r));
  }
  return out;
}

void main() {
  test('returns method = mle', () {
    final result = MLEEstimator().estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.method, EstimationMethod.mle);
  });

  test('theta is positive', () {
    final result = MLEEstimator().estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.theta, greaterThan(0));
  });

  test('mu recovers planted value within 2 units (n=1000)', () {
    final result = MLEEstimator().estimate(_meanReverting(n: 1000), dt: 1.0);
    expect(result.mu, closeTo(10.0, 2.0));
  });

  test('sigma is positive and finite', () {
    final result = MLEEstimator().estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.sigma, greaterThan(0));
    expect(result.sigma.isFinite, isTrue);
  });

  test('rSquared is in [0, 1]', () {
    final result = MLEEstimator().estimate(_meanReverting(n: 200), dt: 1.0);
    expect(result.rSquared, inInclusiveRange(0.0, 1.0));
  });

  test('numObservations equals series.length - 1', () {
    final series = _meanReverting(n: 150);
    final result = MLEEstimator().estimate(series, dt: 1.0);
    expect(result.numObservations, 149);
  });

  test('throws InsufficientDataException when series.length < 3', () {
    expect(
      () => MLEEstimator().estimate([1.0, 2.0]),
      throwsA(isA<InsufficientDataException>()),
    );
  });

  test('throws ArgumentError when dt <= 0', () {
    expect(
      () => MLEEstimator().estimate(_meanReverting(n: 50), dt: 0.0),
      throwsA(isA<ArgumentError>()),
    );
  });
}
