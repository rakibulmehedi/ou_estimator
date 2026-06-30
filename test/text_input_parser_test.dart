import 'package:flutter_test/flutter_test.dart';
import 'package:ou_estimator/data/services/text_input_parser.dart';

void main() {
  const parser = TextInputParser();

  test('newline input: one value per line', () {
    final r = parser.parse('1\n2.5\n3');
    expect(r.values, [1.0, 2.5, 3.0]);
    expect(r.error, isNull);
  });

  test('newline input: takes first numeric column, skips header row', () {
    final r = parser.parse('price,volume\n10,500\n11,600\n12,700');
    expect(r.values, [10.0, 11.0, 12.0]);
    expect(r.error, isNull);
  });

  test('strips currency symbols and spaces', () {
    final r = parser.parse(r'$10, $11, £12');
    expect(r.values, [10.0, 11.0, 12.0]);
  });

  test('single line: splits on commas and whitespace', () {
    final r = parser.parse('1, 2 3\t4');
    expect(r.values, [1.0, 2.0, 3.0, 4.0]);
    expect(r.warning, isNull);
  });

  test('single-line thousands grouping raises a non-blocking warning', () {
    final r = parser.parse('1,000 2,000');
    expect(r.warning, isNotNull);
  });

  test('empty input: error, not throw', () {
    final r = parser.parse('   ');
    expect(r.values, isEmpty);
    expect(r.error, isNotNull);
    expect(r.canCompute, isFalse);
  });

  test('bad token: error with partial values', () {
    final r = parser.parse('1, x, 3');
    expect(r.error, isNotNull);
    expect(r.values, [1.0]); // parsed before the bad token
  });

  test('count, min, max', () {
    final r = parser.parse('3\n1\n2');
    expect(r.count, 3);
    expect(r.min, 1.0);
    expect(r.max, 3.0);
  });

  test('canCompute gates on >= 3 valid points', () {
    expect(parser.parse('1\n2').canCompute, isFalse);
    expect(parser.parse('1\n2\n3').canCompute, isTrue);
  });

  // --- Edge cases: trailing commas, double commas, accidental spaces ---

  test('single-line trailing comma: not an error', () {
    final r = parser.parse('1,2,3,');
    expect(r.values, [1.0, 2.0, 3.0]);
    expect(r.error, isNull);
  });

  test('single-line double comma: treated as single separator', () {
    final r = parser.parse('1,,2,,3');
    expect(r.values, [1.0, 2.0, 3.0]);
    expect(r.error, isNull);
  });

  test('single-line extra spaces around commas: parsed correctly', () {
    final r = parser.parse('1 , 2 , 3');
    expect(r.values, [1.0, 2.0, 3.0]);
    expect(r.error, isNull);
  });

  test('multiline: line starting with comma reads first numeric token', () {
    final r = parser.parse(',10\n20\n30');
    expect(r.values, [10.0, 20.0, 30.0]);
    expect(r.error, isNull);
  });

  test('multiline: comma-only line is skipped silently', () {
    final r = parser.parse('10\n,,\n20\n30');
    expect(r.values, [10.0, 20.0, 30.0]);
    expect(r.error, isNull);
  });
}
