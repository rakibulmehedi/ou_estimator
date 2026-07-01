import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/use_cases/ou_estimator.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/glass_card.dart';

/// Four fit-diagnostic glass cards: R², s, ln L, N.
/// Pure presentation — values come from [result].
class DiagnosticsPanel extends StatelessWidget {
  const DiagnosticsPanel({super.key, required this.result});

  final OUResult result;

  static const double _cardAspectRatio = 1.85;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric('R²', 'Goodness of Fit', result.rSquared.toStringAsFixed(4), ''),
      _Metric('s', 'Residual Std', result.residualStd.toStringAsFixed(4), ''),
      _Metric('ln L', 'Log-Likelihood', result.logLikelihood.toStringAsFixed(2), ''),
      _Metric('N', 'Observations', result.numObservations.toString(), 'pairs'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: _cardAspectRatio,
      mainAxisSpacing: Spacing.md,
      crossAxisSpacing: Spacing.md,
      children: [
        for (var i = 0; i < items.length; i++)
          _DiagnosticCard(metric: items[i], index: i),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.symbol, this.label, this.value, this.unit);
  final String symbol;
  final String label;
  final String value;
  final String unit;
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.metric, required this.index});

  final _Metric metric;
  final int index;

  static final TextStyle _symbolStyle = AppTheme.mono(
    color: AppTheme.accent,
    fontSize: FontSize.xl,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _labelStyle = AppTheme.sans(
    color: AppTheme.textSecondary,
    fontSize: FontSize.md,
  );
  static final TextStyle _valueStyle = AppTheme.mono(
    color: AppTheme.textPrimary,
    fontSize: FontSize.xxl,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle _unitStyle = AppTheme.sans(
    color: AppTheme.textSecondary,
    fontSize: FontSize.sm,
  );

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Semantics(
        label: '${metric.label}: ${metric.value} ${metric.unit}'.trim(),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(metric.symbol, style: _symbolStyle),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      metric.label,
                      style: _labelStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(metric.value, style: _valueStyle),
              if (metric.unit.isNotEmpty)
                Text(metric.unit, style: _unitStyle),
            ],
          ),
        ),
      ),
    );

    return card
        .animate(delay: Motion.stagger * index)
        .fadeIn(duration: Motion.slow, curve: Motion.curve)
        .slideY(begin: Motion.enterSlide, end: 0, duration: Motion.slow, curve: Motion.curve);
  }
}
