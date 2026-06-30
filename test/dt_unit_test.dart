import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/domain/value/dt_unit.dart';

void main() {
  test('labels are singular', () {
    expect(DtUnit.steps.label, 'step');
    expect(DtUnit.days.label, 'day');
    expect(DtUnit.years.label, 'year');
  });

  test('seconds factors are correct', () {
    expect(DtUnit.steps.secondsPerUnit, 1);
    expect(DtUnit.seconds.secondsPerUnit, 1);
    expect(DtUnit.minutes.secondsPerUnit, 60);
    expect(DtUnit.hours.secondsPerUnit, 3600);
    expect(DtUnit.days.secondsPerUnit, 86400);
    expect(DtUnit.weeks.secondsPerUnit, 604800);
    expect(DtUnit.months.secondsPerUnit, 2592000); // 30 days (approx)
    expect(DtUnit.years.secondsPerUnit, 31536000); // 365 days (approx)
  });

  test('all eight units exist', () {
    expect(DtUnit.values.length, 8);
  });
}
