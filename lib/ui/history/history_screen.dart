import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import 'widgets/history_run_card.dart';

/// Shows all saved estimation runs. Tapping a run loads it back into
/// the estimator screen.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load history: $e',
            style:
                TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 56,
                      color: AppTheme.textPrimary.withValues(alpha: 0.18)),
                  const SizedBox(height: Spacing.md),
                  Text('Saved runs appear here',
                      style: AppTheme.sans(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: Spacing.sm),
            itemCount: runs.length,
            itemBuilder: (_, i) => HistoryRunCard(metrics: runs[i]),
          );
        },
      ),
    );
  }
}
