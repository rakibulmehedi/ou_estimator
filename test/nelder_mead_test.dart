import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/use_cases/nelder_mead.dart';

void main() {
  test('minimizes x^2 + y^2 to near (0, 0)', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) => p[0] * p[0] + p[1] * p[1],
      [1.0, 1.0],
    );
    expect(result[0], closeTo(0.0, 1e-4));
    expect(result[1], closeTo(0.0, 1e-4));
  });

  test('minimizes (x-3)^2 + (y+2)^2 to near (3, -2)', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) {
        final dx = p[0] - 3;
        final dy = p[1] + 2;
        return dx * dx + dy * dy;
      },
      [0.0, 0.0],
    );
    expect(result[0], closeTo(3.0, 1e-4));
    expect(result[1], closeTo(-2.0, 1e-4));
  });

  test('minimizes a 3D quadratic near the origin', () {
    const nm = NelderMead();
    final result = nm.minimize(
      (p) => p[0] * p[0] + p[1] * p[1] + p[2] * p[2],
      [5.0, -3.0, 2.0],
    );
    expect(result[0], closeTo(0.0, 1e-4));
    expect(result[1], closeTo(0.0, 1e-4));
    expect(result[2], closeTo(0.0, 1e-4));
  });
}
