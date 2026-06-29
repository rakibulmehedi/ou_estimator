import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ou_metrics.dart';
import '../../../domain/value/estimation_method.dart';
import '../../../providers/providers.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// One item in the history list. Tapping loads the series back into
/// the estimation screen.
class HistoryRunCard extends ConsumerWidget {
  const HistoryRunCard({super.key, required this.metrics});

  final OUMetrics metrics;

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(estimationRepositoryProvider);
    final svc = ref.read(exportServiceProvider);

    void handleTap() {
      final ds = metrics.dataset.value;
      if (ds == null) return;
      ref
          .read(estimationControllerProvider.notifier)
          .loadFromHistory(ds.values, ds.samplingIntervalSeconds);
      ref.read(selectedTabProvider.notifier).state = 0;
    }

    Future<void> handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete run?'),
          content: Text(
              'Delete "${metrics.datasetName}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.delete(metrics.id);
        ref.invalidate(historyProvider);
      }
    }

    Future<void> handleRename() async {
      final controller =
          TextEditingController(text: metrics.datasetName);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename run'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        ),
      );
      if (newName != null &&
          newName.isNotEmpty &&
          newName != metrics.datasetName) {
        await repo.rename(metrics.id, newName);
        ref.invalidate(historyProvider);
      }
    }

    Future<void> handleShare() async {
      final json = svc.metricsToJson(metrics);
      try {
        await svc.share(json, runName: metrics.datasetName);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')),
          );
        }
      }
    }

    final methodBadgeColor = metrics.method == EstimationMethod.mle
        ? AppTheme.accent
        : AppTheme.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs),
      child: ListTile(
        onTap: handleTap,
        title: Text(
          metrics.datasetName,
          style: AppTheme.sans(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'θ=${metrics.theta.toStringAsFixed(3)}  '
          't½=${metrics.halfLife.toStringAsFixed(2)}  '
          '${_relativeTime(metrics.estimatedAt)}',
          style:
              AppTheme.sans(color: AppTheme.textSecondary, fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
                color: methodBadgeColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            metrics.method.name.toUpperCase(),
            style: AppTheme.mono(
                color: methodBadgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 18),
              tooltip: 'Export JSON',
              onPressed: handleShare,
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline, size: 18),
              tooltip: 'Rename',
              onPressed: handleRename,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete',
              onPressed: handleDelete,
            ),
          ],
        ),
      ),
    );
  }
}
