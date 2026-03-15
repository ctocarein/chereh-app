import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Breakpoints — basés sur la largeur physique de l'écran (dp)
// ---------------------------------------------------------------------------

abstract class Breakpoints {
  /// < 360 dp — petits téléphones (iPhone SE 1ère gen, Moto E)
  static const double xs = 360;

  /// 360–399 dp — téléphones Android standard
  static const double sm = 400;

  /// 400–479 dp — grands téléphones (iPhone Pro Max, Galaxy S)
  static const double md = 480;

  /// 480–599 dp — phablets
  static const double lg = 600;

  /// ≥ 600 dp — tablettes et plus
  static const double xl = 840;
}

// ---------------------------------------------------------------------------
// AppResponsive — utilitaire principal
// ---------------------------------------------------------------------------

/// Accessible via [context.rp] depuis n'importe quel widget.
///
/// ```dart
/// final rp = context.rp;
/// Padding(padding: EdgeInsets.symmetric(horizontal: rp.hPad), ...)
/// ```
class AppResponsive {
  final double screenW;
  final double screenH;
  final EdgeInsets safeArea; // MediaQuery.paddingOf

  const AppResponsive._({
    required this.screenW,
    required this.screenH,
    required this.safeArea,
  });

  factory AppResponsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AppResponsive._(
      screenW: mq.size.width,
      screenH: mq.size.height,
      safeArea: mq.padding,
    );
  }

  // ── Catégories ─────────────────────────────────────────────────────────────

  bool get isXs     => screenW < Breakpoints.xs;
  bool get isSm     => screenW >= Breakpoints.xs  && screenW < Breakpoints.sm;
  bool get isMd     => screenW >= Breakpoints.sm  && screenW < Breakpoints.md;
  bool get isLg     => screenW >= Breakpoints.md  && screenW < Breakpoints.lg;
  bool get isTablet => screenW >= Breakpoints.lg;
  bool get isWide   => screenW >= Breakpoints.xl;

  bool get isPhone  => !isTablet;

  // ── Padding horizontal ─────────────────────────────────────────────────────

  /// Padding horizontal principal des écrans.
  double get hPad => switch (screenW) {
        < Breakpoints.xs => 16,
        < Breakpoints.sm => 20,
        < Breakpoints.md => 24,
        < Breakpoints.lg => 32,
        < Breakpoints.xl => 48,
        _                => 80,
      };

  /// Padding compact (cartes, listes internes).
  double get hPadSm => hPad * 0.7;

  // ── Espacements verticaux ──────────────────────────────────────────────────

  double get spXS => isTablet ? 8  : 6;
  double get spS  => isTablet ? 14 : 10;
  double get spM  => isTablet ? 24 : 16;
  double get spL  => isTablet ? 40 : 24;
  double get spXL => isTablet ? 64 : 40;

  // ── Tailles de composants ──────────────────────────────────────────────────

  double get buttonH  => isTablet ? 56 : 50;
  double get avatarSz => isTablet ? 48 : 38;
  double get iconSz   => isTablet ? 28 : 22;
  double get logoSz   => isTablet ? 96 : 72;

  // ── Rayons ─────────────────────────────────────────────────────────────────

  double get radiusS  => 8;
  double get radiusM  => isTablet ? 16 : 12;
  double get radiusL  => isTablet ? 24 : 16;
  double get radiusXL => isTablet ? 32 : 22;

  // ── Typographie ────────────────────────────────────────────────────────────

  /// Facteur d'échelle pour compenser les très petits écrans.
  double get fontScale => isXs ? 0.92 : 1.0;

  double fs(double base) => base * fontScale;

  // ── Largeur max (centrage tablette) ────────────────────────────────────────

  double get maxContentW => isTablet ? 560.0 : double.infinity;
  double get maxCardW    => isTablet ? 480.0 : double.infinity;

  // ── Helpers layout ─────────────────────────────────────────────────────────

  /// Enveloppe [child] dans un [ConstrainedBox] centré sur tablette.
  Widget constrain(Widget child) {
    if (!isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentW),
        child: child,
      ),
    );
  }

  /// Renvoie [tablet] sur tablette, [phone] sinon.
  T when<T>({required T phone, required T tablet}) =>
      isTablet ? tablet : phone;

  /// Renvoie la valeur correspondant à la catégorie de l'écran.
  T sw<T>({
    required T xs,
    required T sm,
    T? md,
    T? lg,
    T? tablet,
  }) {
    if (isTablet && tablet != null) return tablet;
    if (isLg && lg != null) return lg;
    if (isMd && md != null) return md;
    if (isXs || isSm) return xs;   // xs/sm → même valeur
    return sm;
  }
}

// ---------------------------------------------------------------------------
// Extension BuildContext
// ---------------------------------------------------------------------------

extension AppResponsiveX on BuildContext {
  /// Raccourci : `context.rp.hPad`, `context.rp.isTablet`, etc.
  AppResponsive get rp => AppResponsive.of(this);
}

// ---------------------------------------------------------------------------
// Widget utilitaire : centre + contraint le contenu sur tablette
// ---------------------------------------------------------------------------

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final rp = context.rp;
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? rp.maxContentW),
      child: child,
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Center(child: content);
  }
}

// ---------------------------------------------------------------------------
// Widget utilitaire : padding horizontal adaptatif
// ---------------------------------------------------------------------------

class HorizontalPad extends StatelessWidget {
  final Widget child;
  final double? extra; // padding supplémentaire (s'ajoute à hPad)

  const HorizontalPad({super.key, required this.child, this.extra});

  @override
  Widget build(BuildContext context) {
    final pad = context.rp.hPad + (extra ?? 0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: child,
    );
  }
}
