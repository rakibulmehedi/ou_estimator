import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/isar_service.dart';
import 'providers/providers.dart';
import 'ui/core/theme.dart';
import 'ui/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Swaps the red "red screen of death" with a neutral fallback widget.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Scaffold(
      body: Center(
        child: Icon(Icons.error_outline, size: 48),
      ),
    );
  };

  // Catches Flutter framework errors (e.g. build-phase exceptions).
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) FlutterError.presentError(details);
  };

  // Catches unhandled async errors that reach the platform dispatcher.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
    // TODO: forward to crash reporting (e.g. Firebase Crashlytics) in release
    return true;
  };

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
      home: const AppShell(),
    );
  }
}
