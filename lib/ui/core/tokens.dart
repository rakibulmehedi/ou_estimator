import 'package:flutter/material.dart';

/// Layout + motion design tokens. Pure const — single source of truth for
/// spacing, corner radii, animation timing, and responsive breakpoints.
/// Color tokens live in [AppTheme] (lib/ui/core/theme.dart).
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class Radii {
  Radii._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class FontSize {
  FontSize._();
  static const double xs = 10;
  static const double sm = 11;
  static const double md = 12;
  static const double lg = 13;
  static const double body = 15;
  static const double xl = 18;
  static const double title = 20;
  static const double xxl = 24;
}

class IconSize {
  IconSize._();
  static const double sm = 16;
  static const double md = 18;
  static const double lg = 20;
  static const double hero = 56;
}

class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 80);
  static const Curve curve = Curves.easeOutCubic;
  static const double enterSlide = 0.1;
}

/// Responsive width breakpoints. Rail appears at [medium]+, the two-pane
/// master/detail layout appears at [expanded]+.
class Breakpoints {
  Breakpoints._();
  static const double medium = 600;
  static const double expanded = 840;
  static const double contentMaxWidth = 640;

  static bool isCompact(double width) => width < medium;
  static bool useRail(double width) => width >= medium;
  static bool isTwoPane(double width) => width >= expanded;
}
