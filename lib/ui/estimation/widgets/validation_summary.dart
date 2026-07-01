import 'package:flutter/material.dart';

import '../../../data/services/text_input_parser.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// Live, inline summary of a [ParseResult]: a red error line, an amber warning
/// (with the green summary above it), or a green "N points · min…max" line.
/// Pure presentation — pass it the current [ParseResult].
class ValidationSummary extends StatelessWidget {
  const ValidationSummary({super.key, required this.result});

  final ParseResult result;

  // Amber advisory tone (no dedicated theme token; local to this widget).
  static const Color _amber = Color(0xFFD29922);

  @override
  Widget build(BuildContext context) {
    if (result.error != null) {
      return _Line(
        icon: Icons.error_outline,
        color: AppTheme.negative,
        text: result.error!,
      );
    }

    final summary = StringBuffer('${result.count} points');
    if (result.min != null && result.max != null) {
      summary
        ..write('  ·  min ${result.min!.toStringAsFixed(2)}')
        ..write('  ·  max ${result.max!.toStringAsFixed(2)}');
    }

    final summaryLine = _Line(
      icon: Icons.check_circle_outline,
      color: AppTheme.positive,
      text: summary.toString(),
    );

    if (result.warning != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summaryLine,
          const SizedBox(height: Spacing.xs),
          _Line(
            icon: Icons.warning_amber_outlined,
            color: _amber,
            text: result.warning!,
          ),
        ],
      );
    }
    return summaryLine;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: IconSize.sm, color: color),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(text, style: AppTheme.sans(fontSize: FontSize.md, color: color)),
        ),
      ],
    );
  }
}
