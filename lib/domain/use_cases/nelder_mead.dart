import 'dart:math' as math;

/// Nelder-Mead simplex optimizer. Minimizes a scalar function over R^n.
///
/// Standard parameters: α=1 (reflection), γ=2 (expansion),
/// ρ=0.5 (contraction), σ=0.5 (shrink).
class NelderMead {
  const NelderMead({
    this.alpha = 1.0,
    this.gamma = 2.0,
    this.rho = 0.5,
    this.sigma = 0.5,
  });

  final double alpha;
  final double gamma;
  final double rho;
  final double sigma;

  /// Returns the minimizer of [f] starting from [x0].
  List<double> minimize(
    double Function(List<double>) f,
    List<double> x0, {
    double tolerance = 1e-8,
    int maxIter = 10000,
  }) {
    final n = x0.length;

    // Build n+1 initial simplex vertices.
    final simplex = List<List<double>>.generate(n + 1, (i) {
      final p = List<double>.of(x0);
      if (i > 0) {
        p[i - 1] +=
            p[i - 1].abs() > 1e-12 ? 0.05 * p[i - 1].abs() : 0.00025;
      }
      return p;
    });
    final fv = simplex.map(f).toList();

    for (var iter = 0; iter < maxIter; iter++) {
      final idx = List.generate(n + 1, (i) => i)
        ..sort((a, b) => fv[a].compareTo(fv[b]));
      final sTmp = idx.map((i) => simplex[i]).toList();
      final fTmp = idx.map((i) => fv[i]).toList();
      for (var i = 0; i <= n; i++) {
        simplex[i] = sTmp[i];
        fv[i] = fTmp[i];
      }

      var maxDist = 0.0;
      for (var i = 1; i <= n; i++) {
        var d = 0.0;
        for (var j = 0; j < n; j++) {
          final diff = simplex[i][j] - simplex[0][j];
          d += diff * diff;
        }
        if (d > maxDist) maxDist = d;
      }
      if (math.sqrt(maxDist) < tolerance) break;

      final c = List.filled(n, 0.0);
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          c[j] += simplex[i][j] / n;
        }
      }

      final xr =
          List.generate(n, (j) => c[j] + alpha * (c[j] - simplex[n][j]));
      final fr = f(xr);

      if (fr < fv[0]) {
        final xe = List.generate(n, (j) => c[j] + gamma * (xr[j] - c[j]));
        final fe = f(xe);
        simplex[n] = fe < fr ? xe : xr;
        fv[n] = fe < fr ? fe : fr;
      } else if (fr < fv[n - 1]) {
        simplex[n] = xr;
        fv[n] = fr;
      } else {
        final xc = List.generate(
            n, (j) => c[j] + rho * (simplex[n][j] - c[j]));
        final fc = f(xc);
        if (fc < fv[n]) {
          simplex[n] = xc;
          fv[n] = fc;
        } else {
          for (var i = 1; i <= n; i++) {
            simplex[i] = List.generate(
              n,
              (j) => simplex[0][j] + sigma * (simplex[i][j] - simplex[0][j]),
            );
            fv[i] = f(simplex[i]);
          }
        }
      }
    }

    return simplex[0];
  }
}
