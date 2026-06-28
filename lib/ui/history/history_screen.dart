import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tokens.dart';

/// Placeholder for sub-project #4 (saved-run history). Renders an honest
/// empty state so the shell has a real second destination without faking data.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 56, color: AppTheme.textPrimary.withValues(alpha: 0.18)),
            const SizedBox(height: Spacing.md),
            Text('Saved runs appear here',
                style: AppTheme.sans(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
