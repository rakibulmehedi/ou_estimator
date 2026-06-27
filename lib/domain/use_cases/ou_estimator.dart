import 'dart:math' as math;

/// Immutable result of an Ornstein-Uhlenbeck OLS parameter estimation.
class OUResult {
  final double theta; // mean-reversion speed
  final double mu; // equilibrium / long-run mean
  final double sigma; // volatility
  final double halfLife; // ln(2) / theta

  const OUResult({
    required this.theta,
    required this.mu,
    required this.sigma,
    required this.halfLife,
  });

  @override
  String toString() =>
      'OUResult(theta: $theta, mu: $mu, sigma: $sigma, halfLife: $halfLife)';
}

/// Thrown when the series is too short to estimate
/// (length < [OUEstimator.minLength]).
class InsufficientDataException implements Exception {
  final String message;
  const InsufficientDataException(this.message);
  @override
  String toString() => 'InsufficientDataException: $message';
}

/// Thrown when the series is not mean-reverting: estimated AR(1) coefficient
/// b >= 1 (primary rule), or b <= 0, or zero-variance input.
class NonStationaryException implements Exception {
  final String message;
  const NonStationaryException(this.message);
  @override
  String toString() => 'NonStationaryException: $message';
}

/// Estimates Ornstein-Uhlenbeck parameters via OLS on the discretized
/// AR(1) form.
///
///   dX = theta*(mu - X)*dt + sigma*dW
///   X_{t+1} = a + b*X_t + eps,   eps ~ N(0, s^2)
///
/// Recovery:
///   theta    = -ln(b) / dt
///   mu       = a / (1 - b)
///   sigma    = s * sqrt( 2*theta / (1 - b^2) )
///   halfLife = ln(2) / theta
class OUEstimator {
  /// Minimum number of observations required to attempt an estimate.
  static const int minLength = 3;

  OUResult estimate(List<double> series, {double dt = 1.0}) {
    if (series.length < minLength) {
      throw InsufficientDataException(
        'Need at least $minLength observations, got ${series.length}.',
      );
    }
    if (dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'must be > 0');
    }

    // Consecutive pairs: x = X_t, y = X_{t+1}.
    final n = series.length - 1;
    final x = series.sublist(0, n);
    final y = series.sublist(1, n + 1);

    final meanX = _mean(x);
    final meanY = _mean(y);

    double sxx = 0.0; // sum (x - meanX)^2
    double sxy = 0.0; // sum (x - meanX)(y - meanY)
    for (var i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      sxx += dx * dx;
      sxy += dx * (y[i] - meanY);
    }

    if (sxx == 0.0) {
      throw const NonStationaryException(
        'Input series is constant (zero variance); cannot estimate.',
      );
    }

    final b = sxy / sxx; // AR(1) slope
    final a = meanY - b * meanX; // intercept

    if (b >= 1.0) {
      throw NonStationaryException(
        'Estimated AR(1) coefficient b=$b >= 1 '
        '(non-stationary / not mean-reverting).',
      );
    }
    if (b <= 0.0) {
      throw NonStationaryException(
        'Estimated AR(1) coefficient b=$b <= 0 (no valid mean reversion).',
      );
    }

    // Residual standard deviation s (OLS, n-2 degrees of freedom).
    double sse = 0.0;
    for (var i = 0; i < n; i++) {
      final resid = y[i] - (a + b * x[i]);
      sse += resid * resid;
    }
    final dof = (n - 2) > 0 ? (n - 2) : 1;
    final s = math.sqrt(sse / dof);

    final theta = -math.log(b) / dt;
    final mu = a / (1.0 - b);
    final sigma = s * math.sqrt(2.0 * theta / (1.0 - b * b));
    final halfLife = math.log(2) / theta;

    return OUResult(theta: theta, mu: mu, sigma: sigma, halfLife: halfLife);
  }

  double _mean(List<double> v) {
    var sum = 0.0;
    for (final e in v) {
      sum += e;
    }
    return sum / v.length;
  }
}
