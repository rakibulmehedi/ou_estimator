import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/use_cases/ou_estimator.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/glass_card.dart';

/// Grid of the four estimated O–U parameters, rendered as frosted glass panels
/// with a staggered entrance. Pure presentation: values come from [result],
/// which the screen reads from the existing Riverpod provider — this widget
/// holds no state and registers no listeners.
class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key, required this.result, this.unitLabel = 'step'});

  final OUResult result;

  /// Singular Δt unit label (e.g. 'day') for θ ("per <label>") and half-life.
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final items = <_Metric>[
      _Metric('θ', 'Mean Reversion', result.theta.toStringAsFixed(4),
          'per $unitLabel'),
      _Metric('μ', 'Equilibrium', result.mu.toStringAsFixed(4), 'long-run mean'),
      _Metric('σ', 'Volatility', result.sigma.toStringAsFixed(4), 'diffusion'),
      _Metric('t½', 'Half-Life', result.halfLife.toStringAsFixed(3),
          '${unitLabel}s'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.85,
      mainAxisSpacing: Spacing.md,
      crossAxisSpacing: Spacing.md,
      children: [
        for (var i = 0; i < items.length; i++)
          _MetricCard(metric: items[i], index: i),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.index});

  final _Metric metric;
  final int index;

  // Styles depend only on static tokens — hoisted to avoid per-build allocation.
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
  // textSecondary (≈5.6:1 on the glass card) clears WCAG AA at this small size.
  static final TextStyle _unitStyle = AppTheme.sans(
    color: AppTheme.textSecondary,
    fontSize: FontSize.sm,
  );

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Semantics(
        label: '${metric.label}: ${metric.value} ${metric.unit}',
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
              Text(metric.unit, style: _unitStyle),
            ],
          ),
        ),
      ),
    );

    // Presentation-only staggered entrance. No rebuild/state coupling.
    return card
        .animate(delay: Motion.stagger * index)
        .fadeIn(duration: Motion.slow, curve: Motion.curve)
        .slideY(begin: Motion.enterSlide, end: 0, duration: Motion.slow, curve: Motion.curve);
  }
}
