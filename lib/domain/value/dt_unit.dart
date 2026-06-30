/// Sampling interval unit for a price series. The numeric Δt value (not the
/// unit's [secondsPerUnit]) feeds `OUEstimator.estimate(series, dt: value)`;
/// [secondsPerUnit] converts the value to the persisted
/// `samplingIntervalSeconds`. [label] is singular and used to annotate θ
/// ("per <label>") and half-life ("<label>s").
///
/// The field is `secondsPerUnit` rather than `seconds`: a `seconds` instance
/// field would collide with the `DtUnit.seconds` enum value.
///
/// `months` and `years` use calendar approximations (30 / 365 days).
enum DtUnit {
  steps(label: 'step', secondsPerUnit: 1),
  seconds(label: 'second', secondsPerUnit: 1),
  minutes(label: 'minute', secondsPerUnit: 60),
  hours(label: 'hour', secondsPerUnit: 3600),
  days(label: 'day', secondsPerUnit: 86400),
  weeks(label: 'week', secondsPerUnit: 604800),
  months(label: 'month', secondsPerUnit: 2592000),
  years(label: 'year', secondsPerUnit: 31536000);

  const DtUnit({required this.label, required this.secondsPerUnit});

  final String label;
  final int secondsPerUnit;
}
