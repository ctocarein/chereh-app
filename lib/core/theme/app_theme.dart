import 'package:flutter/material.dart';

/// Tokens sémantiques de la palette CheReh.
/// Utiliser ces constantes plutôt que les couleurs brutes.
abstract class AppColors {
  // --- Fondations ---
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF2E3A40); // gris-ardoise foncé
  static const muted = Color(0xFF5F6B73); // texte secondaire / labels
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F6F8); // inputs, fonds alternatifs
  static const disabled = Color(0xFFC9D1D6);

  // --- Brand (teal) ---
  static const brand = Color(0xFF1FA6B8);
  // color-mix(brand 75% + foreground 25%)
  static const brandStrong = Color(0xFF238B9A);
  // color-mix(brand 18% + white 82%)
  static const brandSoft = Color(0xFFD7EFF2);

  // --- Accent (rose / fuchsia) ---
  static const accent = Color(0xFFE94C89);
  // color-mix(accent 20% + white 80%)
  static const accentSoft = Color(0xFFFBDBE7);

  // --- Support ---
  static const support = Color(0xFF6BCF9C); // succès, validation
  static const warning = Color(0xFFF2B94B); // alertes, attention
}

abstract class AppTheme {
  static const _light = ColorScheme(
    brightness: Brightness.light,
    // Brand — teal
    primary: AppColors.brand,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.foreground,
    // Accent — rose
    secondary: AppColors.accent,
    onSecondary: AppColors.background,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: AppColors.foreground,
    // Tertiary — vert succès
    tertiary: AppColors.support,
    onTertiary: AppColors.background,
    tertiaryContainer: Color(0xFFD5F5E5),
    onTertiaryContainer: AppColors.foreground,
    // Erreur
    error: Color(0xFFB00020),
    onError: AppColors.background,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    // Surfaces & fonds
    surface: AppColors.surface,
    onSurface: AppColors.foreground,
    surfaceContainerHighest: AppColors.surfaceAlt,
    onSurfaceVariant: AppColors.muted,
    // Contours
    outline: AppColors.muted,
    outlineVariant: AppColors.disabled,
    // Divers
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.foreground,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.brandSoft,
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandSoft,
    onPrimary: AppColors.foreground,
    primaryContainer: AppColors.brandStrong,
    onPrimaryContainer: AppColors.background,
    secondary: AppColors.accentSoft,
    onSecondary: AppColors.foreground,
    secondaryContainer: Color(0xFF7A1A3F),
    onSecondaryContainer: AppColors.accentSoft,
    tertiary: AppColors.support,
    onTertiary: AppColors.foreground,
    tertiaryContainer: Color(0xFF1A5C3A),
    onTertiaryContainer: Color(0xFFD5F5E5),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1C2326),
    onSurface: Color(0xFFE0E5E8),
    surfaceContainerHighest: Color(0xFF2A3338),
    onSurfaceVariant: AppColors.disabled,
    outline: Color(0xFF8A9499),
    outlineVariant: Color(0xFF3A4448),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE0E5E8),
    onInverseSurface: Color(0xFF1C2326),
    inversePrimary: AppColors.brand,
  );

  static ThemeData get light => _buildTheme(_light);
  static ThemeData get dark => _buildTheme(_dark);

  static ThemeData _buildTheme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,

        // ── Typographie ──────────────────────────────────────────────────────
        textTheme: _textTheme(scheme.onSurface),

        // ── Inputs ──────────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          fillColor: scheme.surfaceContainerHighest,
          filled: true,
        ),

        // ── FilledButton ─────────────────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── OutlinedButton ───────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── ElevatedButton ───────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── TextButton ───────────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // ── Chips ────────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: scheme.surfaceContainerHighest,
          labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),

        // ── AppBar ───────────────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        ),

        // ── BottomNavBar ─────────────────────────────────────────────────────
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scheme.surface,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),

        // ── Cards ────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant, width: 0.8),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── SnackBar ─────────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: scheme.inverseSurface,
          contentTextStyle:
              TextStyle(color: scheme.onInverseSurface, fontSize: 14),
        ),
      );

  static TextTheme _textTheme(Color c) => TextTheme(
        displayLarge:  _ts(57, FontWeight.w400, c),
        displayMedium: _ts(45, FontWeight.w400, c),
        displaySmall:  _ts(36, FontWeight.w400, c),
        headlineLarge:  _ts(32, FontWeight.w700, c),
        headlineMedium: _ts(28, FontWeight.w700, c),
        headlineSmall:  _ts(24, FontWeight.w600, c),
        titleLarge:  _ts(20, FontWeight.w600, c),
        titleMedium: _ts(16, FontWeight.w600, c),
        titleSmall:  _ts(14, FontWeight.w500, c),
        bodyLarge:  _ts(16, FontWeight.w400, c, h: 1.55),
        bodyMedium: _ts(14, FontWeight.w400, c, h: 1.50),
        bodySmall:  _ts(12, FontWeight.w400, c, h: 1.45),
        labelLarge:  _ts(14, FontWeight.w600, c),
        labelMedium: _ts(12, FontWeight.w500, c),
        labelSmall:  _ts(11, FontWeight.w400, c),
      );

  static TextStyle _ts(
    double size,
    FontWeight weight,
    Color color, {
    double? h,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: h,
        letterSpacing: size >= 20 ? -0.3 : 0.1,
      );
}
