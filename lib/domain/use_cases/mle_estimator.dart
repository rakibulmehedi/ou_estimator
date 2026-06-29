import 'dart:math' as math;

import '../value/estimation_method.dart';
import 'nelder_mead.dart';
import 'ou_estimator.dart';

/// Estimates O-U parameters via MLE on the exact transition density.
///
/// Transition: X_{t+1} | X_t ~ N(m_t, v)
///   m_t = μ + (X_t - μ) * e^{-θΔt}
///   v   = σ² (1 - e^{-2θΔt}) / (2θ)
///
/// Minimizes the negative log-likelihood using Nelder-Mead, initialized
/// from the OLS solution.
class MLEEstimator {
  MLEEstimator({NelderMead? optimizer})
      : _optimizer = optimizer ?? const NelderMead();

  final NelderMead _optimizer;

  OUResult estimate(List<double> series, {double dt = 1.0}) {
    if (series.length < OUEstimator.minLength) {
      throw InsufficientDataException(
        'Need at least ${OUEstimator.minLength} observations, '
        'got ${series.length}.',
      );
    }
    if (dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'must be > 0');
    }

    final n = series.length - 1;
    final x = series.sublist(0, n);
    final y = series.sublist(1);

    // Initialize from OLS
    final ols = OUEstimator().estimate(series, dt: dt);

    double negLogLik(List<double> params) {
      final theta = params[0];
      final mu = params[1];
      final sigma = params[2];
      if (theta <= 0 || sigma <= 0) return 1e30;

      final eFac = math.exp(-theta * dt);
      final v = sigma * sigma * (1 - math.exp(-2 * theta * dt)) / (2 * theta);
      if (v <= 0) return 1e30;

      var sumSq = 0.0;
      for (var i = 0; i < n; i++) {
        final mt = mu + (x[i] - mu) * eFac;
        final diff = y[i] - mt;
        sumSq += diff * diff;
      }
      return n / 2.0 * (math.log(2 * math.pi) + math.log(v)) +
          sumSq / (2 * v);
    }

    final best = _optimizer.minimize(
      negLogLik,
      [ols.theta, ols.mu, ols.sigma],
      tolerance: 1e-8,
      maxIter: 10000,
    );

    final theta = best[0];
    final mu = best[1];
    final sigma = best[2];

    if (theta <= 0) {
      throw NonStationaryException(
        'MLE: estimated θ=$theta ≤ 0 — series is not mean-reverting.',
      );
    }

    // Compute diagnostics at MLE solution.
    final eFac = math.exp(-theta * dt);
    final v = sigma * sigma * (1 - math.exp(-2 * theta * dt)) / (2 * theta);

    var sse = 0.0;
    final meanY = y.reduce((a, b) => a + b) / n;
    var sst = 0.0;
    for (var i = 0; i < n; i++) {
      final mt = mu + (x[i] - mu) * eFac;
      final diff = y[i] - mt;
      sse += diff * diff;
      final dy = y[i] - meanY;
      sst += dy * dy;
    }

    final rSquared = sst == 0.0 ? 1.0 : 1.0 - sse / sst;
    final residualStd = math.sqrt(v);
    final logLikelihood = -negLogLik(best);
    final halfLife = math.log(2) / theta;

    return OUResult(
      theta: theta,
      mu: mu,
      sigma: sigma,
      halfLife: halfLife,
      rSquared: rSquared,
      residualStd: residualStd,
      logLikelihood: logLikelihood,
      numObservations: n,
      method: EstimationMethod.mle,
    );
  }
}
