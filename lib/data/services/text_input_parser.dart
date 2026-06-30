import 'dart:math' as math;

/// Structured outcome of parsing a price-series text input. Non-throwing so the
/// same call serves both the Compute path and live inline validation.
class ParseResult {
  const ParseResult({required this.values, this.error, this.warning});

  /// Values parsed so far. On [error] this holds whatever parsed before the
  /// failure, so callers can still show context.
  final List<double> values;

  /// Blocks Compute (unparseable token / no numbers / empty).
  final String? error;

  /// Non-blocking advisory (e.g. a suspected thousands separator).
  final String? warning;

  int get count => values.length;
  double? get min => values.isEmpty ? null : values.reduce(math.min);
  double? get max => values.isEmpty ? null : values.reduce(math.max);

  /// Estimation needs at least 3 observations and no hard error.
  bool get canCompute => error == null && values.length >= 3;
}

/// Parses a price series from free-form text into a [ParseResult].
///
/// Newline-first and predictable: if the input contains newlines, each line is
/// one observation and only the first numeric column is read (a non-numeric
/// header row is skipped). Without newlines, tokens are split on commas and
/// whitespace. Currency symbols (`$ € £`) and spaces are stripped. A
/// single-line thousands grouping (e.g. `1,000`) raises a non-blocking warning
/// rather than being silently misparsed.
class TextInputParser {
  const TextInputParser();

  static final RegExp _delimiter = RegExp(r'[,\s]+');
  static final RegExp _currency = RegExp(r'[\$€£\s]');
  static final RegExp _thousands = RegExp(r'\d,\d{3}');

  ParseResult parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const ParseResult(
        values: [],
        error: 'Enter a price series to begin.',
      );
    }

    if (text.contains('\n')) {
      return _parseLines(text);
    }
    return _parseSingleLine(text);
  }

  ParseResult _parseLines(String text) {
    final values = <double>[];
    String? error;
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      // Skip lines that contain only delimiters (e.g. ",,").
      final parts = line.split(_delimiter).where((t) => t.isNotEmpty).toList();
      if (parts.isEmpty) continue;
      final firstToken = parts.first;
      final v = double.tryParse(_clean(firstToken));
      if (v == null) {
        // Allow a single leading non-numeric header row to be skipped.
        if (values.isEmpty && i == 0) continue;
        error = '"$firstToken" is not a valid number.';
        break;
      }
      values.add(v);
    }
    if (values.isEmpty && error == null) {
      error = 'No numbers found.';
    }
    return ParseResult(values: values, error: error);
  }

  ParseResult _parseSingleLine(String text) {
    final warning = _thousands.hasMatch(text)
        ? 'Looks like a thousands separator (e.g. 1,000). '
            'Put one value per line to be safe.'
        : null;

    final values = <double>[];
    final tokens = text.split(_delimiter).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      final v = double.tryParse(_clean(t));
      if (v == null) {
        return ParseResult(
          values: values,
          error: '"$t" is not a valid number.',
          warning: warning,
        );
      }
      values.add(v);
    }
    if (values.isEmpty) {
      return const ParseResult(values: [], error: 'No numbers found.');
    }
    return ParseResult(values: values, warning: warning);
  }

  String _clean(String token) => token.replaceAll(_currency, '');
}
