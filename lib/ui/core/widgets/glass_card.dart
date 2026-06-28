import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Frosted-glass surface: a translucent fill over a backdrop blur with a
/// hairline border. Pure presentation — wrap any [child]. Holds no state.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.glassBlur,
            sigmaY: AppTheme.glassBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.glassFill,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
