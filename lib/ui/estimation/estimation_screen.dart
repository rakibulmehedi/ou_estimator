import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import '../core/widgets/section_label.dart';
import 'estimation_controller.dart';
import 'estimation_state.dart';
import 'widgets/metrics_panel.dart';
import 'widgets/price_chart.dart';

/// Single-screen O-U estimator: input → compute → metrics + chart.
class EstimationScreen extends ConsumerStatefulWidget {
  const EstimationScreen({super.key});

  @override
  ConsumerState<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends ConsumerState<EstimationScreen> {
  final _controller = TextEditingController(
    text: '10, 9.4, 9.8, 10.3, 9.9, 10.1, 9.7, 10.0, 10.2, 9.85, 10.05, 9.95',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);

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
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: _buildInput(state, notifier),
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
                      _buildInput(state, notifier),
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

  Widget _buildInput(EstimationState state, EstimationController notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Price series  ·  comma-separated, uniform Δt'),
        const SizedBox(height: Spacing.sm),
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(
            hintText: 'e.g. 10, 9.8, 10.2, 9.9, ...',
          ),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: state.loading
              ? null
              : () => notifier.compute(_controller.text),
          icon: state.loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.calculate_outlined),
          label: const Text('Compute'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: Spacing.lg),
          _ErrorBanner(message: state.error!),
        ],
      ],
    );
  }

  Widget _buildResults(EstimationState state) {
    if (state.hasResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          MetricsPanel(result: state.result!),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
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
