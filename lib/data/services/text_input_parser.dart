/// Parses manual comma-separated (or whitespace/newline) numeric text into a
/// list of doubles.
///
/// No file or CSV access — manual text only (locked §6.2).
class TextInputParser {
  const TextInputParser();

  List<double> parse(String raw) {
    final tokens = raw
        .split(RegExp(r'[,\s]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      throw const FormatException(
        'No numbers found. Enter comma-separated values.',
      );
    }

    final values = <double>[];
    for (final t in tokens) {
      final v = double.tryParse(t);
      if (v == null) {
        throw FormatException('"$t" is not a valid number.');
      }
      values.add(v);
    }
    return values;
  }
}
