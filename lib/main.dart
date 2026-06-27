import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/isar_service.dart';
import 'providers/providers.dart';
import 'ui/core/theme.dart';
import 'ui/estimation/estimation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = await IsarService.open();

  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isarService.db)],
      child: const OUApp(),
    ),
  );
}

class OUApp extends StatelessWidget {
  const OUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O-U Estimator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const EstimationScreen(),
    );
  }
}
