import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/ou_estimator.dart';

/// Standard normal sample via Box-Muller (u1 guarded against 0).
double _gauss(Random r) {
  final u1 = max(r.nextDouble(), 1e-12);
  final u2 = r.nextDouble();
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
}

/// Mean-reverting AR(1): X_{t+1} = a + b*X_t + noise, a = mu*(1-b).
List<double> _meanReverting({
  int n = 500,
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

/// Explosive / unit-root series with b >= 1 (deterministically non-stationary).
List<double> _explosive({
  int n = 300,
  double b = 1.01,
  double noise = 0.5,
  int seed = 7,
}) {
  final r = Random(seed);
  final out = <double>[1.0];
  for (var i = 1; i < n; i++) {
    out.add(b * out.last + noise * _gauss(r));
  }
  return out;
}

/// Pure random walk: X_{t+1} = X_t + noise (true b = 1).
List<double> _randomWalk({int n = 500, double noise = 1.0, int seed = 99}) {
  final r = Random(seed);
  final out = <double>[0.0];
  for (var i = 1; i < n; i++) {
    out.add(out.last + noise * _gauss(r));
  }
  return out;
}

void main() {
  final estimator = OUEstimator();

  test('A: recovers parameters from a mean-reverting series', () {
    final series = _meanReverting(); // planted b=0.7, mu=10
    final result = estimator.estimate(series);

    expect(result.theta, greaterThan(0));
    expect(result.theta.isFinite, isTrue);
    expect(result.sigma, greaterThan(0));
    expect(result.sigma.isFinite, isTrue);
    expect(result.halfLife, greaterThan(0));
    expect(result.halfLife.isFinite, isTrue);
    // Generous band — noise prevents exact recovery.
    expect(result.mu, closeTo(10.0, 2.0));
  });

  test('B: throws NonStationaryException on an explosive (b>=1) series', () {
    final series = _explosive();
    expect(
      () => estimator.estimate(series),
      throwsA(isA<NonStationaryException>()),
    );
  });

  test('C: throws InsufficientDataException when length < 3', () {
    expect(
      () => estimator.estimate(<double>[1.0, 2.0]),
      throwsA(isA<InsufficientDataException>()),
    );
  });

  test('D: pure random walk is non-mean-reverting (tiny theta or throws)', () {
    final series = _randomWalk();
    try {
      final result = estimator.estimate(series);
      // If it estimates, mean reversion must be weak (long half-life).
      expect(result.theta, lessThan(0.1));
    } on NonStationaryException {
      // Also acceptable: b landed >= 1.
    }
  });

  test('dt scales theta inversely and half-life proportionally', () {
    final estimator = OUEstimator();
    final series = _meanReverting(n: 60, b: 0.8, mu: 10.0, noise: 0.3);
    final r1 = estimator.estimate(series, dt: 1.0);
    final r2 = estimator.estimate(series, dt: 2.0);
    expect(r2.theta, closeTo(r1.theta / 2, 1e-9));
    expect(r2.halfLife, closeTo(r1.halfLife * 2, 1e-9));
  });
}
