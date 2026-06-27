import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/services/text_input_parser.dart';

void main() {
  const parser = TextInputParser();

  test('parses comma-separated doubles', () {
    expect(parser.parse('1, 2.5, 3'), [1.0, 2.5, 3.0]);
  });

  test('tolerates whitespace and newlines', () {
    expect(parser.parse('1\n2  3,4'), [1.0, 2.0, 3.0, 4.0]);
  });

  test('parses negative and decimal values', () {
    expect(parser.parse('-1.5, 0, 2.25'), [-1.5, 0.0, 2.25]);
  });

  test('throws FormatException on a non-numeric token', () {
    expect(() => parser.parse('1, x, 3'), throwsFormatException);
  });

  test('throws FormatException on empty input', () {
    expect(() => parser.parse('   '), throwsFormatException);
  });
}
