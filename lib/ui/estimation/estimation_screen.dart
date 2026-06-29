import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import '../core/widgets/section_label.dart';
import 'estimation_state.dart';
import 'widgets/diagnostics_panel.dart';
import 'widgets/input_panel.dart';
import 'widgets/metrics_panel.dart';
import 'widgets/price_chart.dart';

/// Single-screen O-U estimator: input → compute → metrics + chart.
class EstimationScreen extends ConsumerStatefulWidget {
  const EstimationScreen({super.key});

  @override
  ConsumerState<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends ConsumerState<EstimationScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('O–U Parameter Estimator'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoPane = Breakpoints.isTwoPane(constraints.maxWidth);
            if (twoPane) {
              return Row(
                key: const Key('estimation-two-pane'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: InputPanel(),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: _buildResults(state),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const InputPanel(),
                      _buildResults(state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults(EstimationState state) {
    if (state.hasResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          MetricsPanel(result: state.result!, unitLabel: state.unitLabel),
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Fit diagnostics'),
          const SizedBox(height: Spacing.md),
          DiagnosticsPanel(result: state.result!),
          const SizedBox(height: Spacing.xl),
          const SectionLabel('Series & equilibrium (μ)'),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 280,
            child: PriceChart(
              series: state.series,
              mu: state.result!.mu,
            ),
          ),
          const SizedBox(height: Spacing.md),
          const _Legend(),
        ],
      );
    }
    if (state.error == null) {
      return const Padding(
        padding: EdgeInsets.only(top: Spacing.xxl),
        child: _EmptyHint(),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _swatch(scheme.primary, solid: true),
        const SizedBox(width: 6),
        const Text('Price',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 20),
        _swatch(Colors.redAccent, solid: false),
        const SizedBox(width: 6),
        const Text('μ equilibrium',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _swatch(Color color, {required bool solid}) {
    return Container(
      width: 22,
      height: 3,
      decoration: BoxDecoration(
        color: solid ? color : null,
        borderRadius: BorderRadius.circular(2),
        border: solid ? null : Border.all(color: color),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.show_chart,
            size: 56, color: AppTheme.textPrimary.withValues(alpha: 0.18)),
        const SizedBox(height: 12),
        const Text(
          'Enter a price series and tap Compute\nto estimate the O–U parameters.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textTertiary),
        ),
      ],
    );
  }
}
