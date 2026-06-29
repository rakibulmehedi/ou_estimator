import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/text_input_parser.dart';
import '../../../domain/value/dt_unit.dart';
import '../../../domain/value/estimation_method.dart';
import '../../../providers/providers.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/section_label.dart';
import 'validation_summary.dart';

/// Alias so widget tests can name the dropdown's generic type.
typedef DtUnitOption = DtUnit;

// Mean-reverting sample (estimated AR(1) b ≈ 0.51) so the default Compute
// shows a result rather than a non-stationary error. The earlier zig-zag seed
// had b < 0, which the estimator rejects.
const _seedSeries =
    '11.2, 10.51, 10.37, 10.32, 10.02, 10.19, 9.91, 9.89, 9.74, 9.67, 9.84, 10.1';

/// The estimation screen's input column: series text, Δt value + unit, file
/// import, live validation, and a soft-gated Compute button. Owns the text
/// controllers and the Δt/unit selection; reads estimation state via Riverpod.
class InputPanel extends ConsumerStatefulWidget {
  const InputPanel({super.key});

  @override
  ConsumerState<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends ConsumerState<InputPanel> {
  static const _parser = TextInputParser();

  final _seriesController = TextEditingController(text: _seedSeries);
  final _dtController = TextEditingController(text: '1');
  DtUnit _unit = DtUnit.steps;
  late ParseResult _parsed = _parser.parse(_seriesController.text);

  @override
  void initState() {
    super.initState();
    _seriesController.addListener(_reparse);
  }

  @override
  void dispose() {
    _seriesController.removeListener(_reparse);
    _seriesController.dispose();
    _dtController.dispose();
    super.dispose();
  }

  void _reparse() {
    setState(() => _parsed = _parser.parse(_seriesController.text));
  }

  double get _dtValue => double.tryParse(_dtController.text.trim()) ?? 0;

  bool get _canCompute => _parsed.canCompute && _dtValue > 0;

  Future<void> _importFile() async {
    final text = await ref.read(fileImportServiceProvider).pickTextFile();
    if (text == null || !mounted) return;
    _seriesController.text = text.trim();
    // The listener fires on programmatic text changes too, refreshing _parsed.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimationControllerProvider);
    final notifier = ref.read(estimationControllerProvider.notifier);

    ref.listen<String>(seriesTextProvider, (_, next) {
      if (next.isNotEmpty && _seriesController.text != next) {
        _seriesController.text = next;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(seriesTextProvider.notifier).state = '';
          }
        });
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Price series  ·  newline or comma separated'),
        const SizedBox(height: Spacing.sm),
        TextField(
          key: const Key('series-input'),
          controller: _seriesController,
          minLines: 2,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(
            hintText: 'e.g. 10\\n9.8\\n10.2  — or  10, 9.8, 10.2',
          ),
        ),
        const SizedBox(height: Spacing.sm),
        ValidationSummary(result: _parsed),
        const SizedBox(height: Spacing.lg),
        const SectionLabel('Sampling interval (Δt)'),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                key: const Key('dt-value-input'),
                controller: _dtController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(hintText: '1'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: DropdownButton<DtUnitOption>(
                value: _unit,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceElevated,
                items: [
                  for (final u in DtUnit.values)
                    DropdownMenuItem(value: u, child: Text('${u.label}s')),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => _unit = u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SegmentedButton<EstimationMethod>(
          segments: const [
            ButtonSegment(
              value: EstimationMethod.ols,
              label: Text('OLS'),
            ),
            ButtonSegment(
              value: EstimationMethod.mle,
              label: Text('MLE'),
            ),
          ],
          selected: {state.method},
          onSelectionChanged: (selection) =>
              notifier.setMethod(selection.first),
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton.icon(
          onPressed: _importFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import CSV / TXT'),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: (state.loading || !_canCompute)
              ? null
              : () => notifier.compute(
                    _seriesController.text,
                    dt: _dtValue,
                    unit: _unit,
                  ),
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
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
