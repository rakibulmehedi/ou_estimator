import 'package:flutter/material.dart';

import '../estimation/estimation_screen.dart';
import '../history/history_screen.dart';

/// One navigation destination: its icons, label, and the screen it shows.
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;
}

/// App-wide destinations. Adding a screen = one entry here; the shell adapts.
/// Not `const`: the builder closures are not const-constructible.
final List<AppDestination> appDestinations = <AppDestination>[
  AppDestination(
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate,
    label: 'Estimator',
    builder: (_) => const EstimationScreen(),
  ),
  AppDestination(
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: 'History',
    builder: (_) => const HistoryScreen(),
  ),
];
