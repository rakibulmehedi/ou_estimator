import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/tokens.dart';

/// Line chart of the input price series with a horizontal dashed line at the
/// equilibrium mean (μ). Y axis scales dynamically to the series min/max (and
/// always includes μ). Pure presentation — receives [series] and [mu] as plain
/// values from the screen; holds no state.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.series, required this.mu});

  final List<double> series;
  final double mu;

  // Axis / tooltip text styles — hoisted to avoid per-tick allocation.
  static final TextStyle _axisStyle =
      AppTheme.mono(color: AppTheme.textSecondary, fontSize: FontSize.xs);
  static final TextStyle _tooltipStyle = AppTheme.mono(
    color: AppTheme.textPrimary,
    fontSize: FontSize.lg,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    // Presentation leaf must be independently safe: a 0/1-point series has no
    // line to draw and would crash `reduce` / collapse the μ segment.
    if (series.length < 2) return const SizedBox.shrink();

    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];

    final rawMin = series.reduce((a, b) => a < b ? a : b);
    final rawMax = series.reduce((a, b) => a > b ? a : b);

    // Dynamic Y bounds — include μ so the equilibrium line is always visible.
    var minY = rawMin < mu ? rawMin : mu;
    var maxY = rawMax > mu ? rawMax : mu;
    final span = maxY - minY;
    final pad = span == 0 ? 1.0 : span * 0.08;
    minY -= pad;
    maxY += pad;

    final maxX = (series.length - 1).toDouble();

    return RepaintBoundary(
      child: Semantics(
        label: 'Price series line chart. Equilibrium mean μ '
            '${mu.toStringAsFixed(4)}. ${series.length} points, ranging '
            '${rawMin.toStringAsFixed(2)} to ${rawMax.toStringAsFixed(2)}.',
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppTheme.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: _leftTitle,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: _bottomTitle,
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              getTouchedSpotIndicator: (barData, spotIndexes) {
                // Glowing indicator only on the price line (μ line is dashed).
                if (barData.dashArray != null) {
                  return spotIndexes.map((_) => null).toList();
                }
                return spotIndexes.map((_) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      strokeWidth: 1.5,
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: AppTheme.accent,
                        strokeWidth: 3,
                        strokeColor: AppTheme.accent.withValues(alpha: 0.25),
                      ),
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppTheme.surfaceElevated,
                tooltipRoundedRadius: Radii.sm,
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                tooltipBorder: const BorderSide(color: AppTheme.glassBorder),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    // Suppress the μ reference line from the tooltip.
                    if (spot.bar.dashArray != null) return null;
                    return LineTooltipItem(
                      spot.y.toStringAsFixed(4),
                      _tooltipStyle,
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              // Price series — curved line with a glowing accent gradient fill.
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.22,
                preventCurveOverShooting: true,
                color: AppTheme.accent,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.32),
                      AppTheme.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Equilibrium mean μ — horizontal dashed reference line. Kept red
              // to stay consistent with the screen's (locked) legend swatch.
              LineChartBarData(
                spots: [FlSpot(0, mu), FlSpot(maxX, mu)],
                isCurved: false,
                color: AppTheme.negative,
                barWidth: 1.5,
                dashArray: const [8, 4],
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _leftTitle(double value, TitleMeta meta) {
    if (value == meta.min || value == meta.max) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value.toStringAsFixed(1),
        textAlign: TextAlign.right,
        style: _axisStyle,
      ),
    );
  }

  static Widget _bottomTitle(double value, TitleMeta meta) {
    // Float-safe integrality test — fl_chart tick values can carry fp noise.
    if ((value - value.roundToDouble()).abs() > 1e-9) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Text(value.toInt().toString(), style: _axisStyle),
    );
  }
}
