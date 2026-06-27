import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium fintech dark theme for the O–U estimator.
///
/// Typography is bundled offline (see `assets/google_fonts/`): body/labels use
/// Inter, while every numeric metric and chart axis/tooltip label uses
/// JetBrains Mono for tabular alignment. google_fonts resolves both from the
/// bundled assets, so release builds render with no first-paint FOUT.
class AppTheme {
  AppTheme._();

  // --- Surface tokens ---------------------------------------------------
  /// Scaffold / app background.
  static const Color background = Color(0xFF0D1117);

  /// Base card / input surface.
  static const Color surface = Color(0xFF161B22);

  /// Raised surface (tooltips, popovers).
  static const Color surfaceElevated = Color(0xFF1C232E);

  /// Hairline divider / outline (~10% white).
  static const Color border = Color(0x1AFFFFFF);

  // --- Brand / semantic tokens -----------------------------------------
  /// Primary accent (links, focus, price line, touch indicator).
  static const Color accent = Color(0xFF4F8CFF);

  /// Primary foreground text — 16.0:1 on [background] (WCAG AAA).
  static const Color textPrimary = Color(0xFFE6EDF3);

  /// Muted / secondary text — 6.15:1 on [background] (WCAG AA, AAA large).
  static const Color textSecondary = Color(0xFF8B949E);

  /// Tertiary / hint text — used for de-emphasised captions on solid surfaces.
  static const Color textTertiary = Color(0xFF6E7681);

  /// Positive delta (gains).
  static const Color positive = Color(0xFF3FB950);

  /// Negative delta (losses) — also drives [ColorScheme.error].
  static const Color negative = Color(0xFFF85149);

  // --- Glass tokens (frosted metric cards) ------------------------------
  /// Translucent fill layered over [surface] (~8% white).
  static const Color glassFill = Color(0x14FFFFFF);

  /// Glass hairline border (~12% white).
  static const Color glassBorder = Color(0x1FFFFFFF);

  /// Backdrop blur sigma applied behind glass panels.
  static const double glassBlur = 18;

  // --- Type helpers -----------------------------------------------------
  /// Monospaced, tabular numerals for all numeric metrics and chart labels.
  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Inter for body / label text.
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // --- Theme ------------------------------------------------------------
  /// Cached so the full [ThemeData] graph is built once, not per access.
  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      surface: surface,
      error: negative,
      onSurface: textPrimary,
    );

    final base = ThemeData(brightness: Brightness.dark);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: sans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: sans(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: sans(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
