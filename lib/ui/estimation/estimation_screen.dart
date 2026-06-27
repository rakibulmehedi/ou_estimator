import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('O–U Parameter Estimator'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Price series  ·  comma-separated, uniform Δt',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                _ErrorBanner(message: state.error!),
              ],
              if (state.hasResult) ...[
                const SizedBox(height: 24),
                MetricsPanel(result: state.result!),
                const SizedBox(height: 24),
                Text(
                  'Series & equilibrium (μ)',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: PriceChart(
                    series: state.series,
                    mu: state.result!.mu,
                  ),
                ),
                const SizedBox(height: 12),
                const _Legend(),
              ] else if (state.error == null) ...[
                const SizedBox(height: 56),
                const _EmptyHint(),
              ],
            ],
          ),
        ),
      ),
    );
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
        const Text('Price', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(width: 20),
        _swatch(Colors.redAccent, solid: false),
        const SizedBox(width: 6),
        const Text('μ equilibrium',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
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
        Icon(Icons.show_chart, size: 56, color: Colors.white.withValues(alpha: 0.18)),
        const SizedBox(height: 12),
        const Text(
          'Enter a price series and tap Compute\nto estimate the O–U parameters.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }
}
