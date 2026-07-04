import 'package:flutter/material.dart';

/// ChefSync Design Tokens
/// ----------------------
/// A single, deliberate vocabulary for spacing, radius, elevation and
/// semantic color so that every screen we touch — mobile, tablet or
/// desktop — reads as one product instead of a pile of one-off screens.
/// Nothing here changes business logic; this file only exists to be
/// imported by widgets and screens.

/// 4px baseline grid. Commercial ERP UIs (Linear, Stripe, Odoo) read as
/// "considered" because spacing is quantized, not because it's generous.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radius scale. Small radius for dense controls (chips, inputs),
/// larger radius for surfaces that hold content (cards, sheets).
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}

/// Soft, low-opacity shadows instead of Material's default drop shadow —
/// this is the single biggest lever for making a screen feel "premium
/// SaaS" instead of "default Flutter".
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get low => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get high => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.10),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> coloredGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Semantic status colors, kept separate from brand colors so a screen
/// can say "this means success" / "this needs attention" without
/// borrowing the brand palette for meaning it wasn't designed to carry.
class AppStatusColors {
  AppStatusColors._();

  static const Color success = Color(0xFF16A34A);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSurface = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFEFF6FF);
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralSurface = Color(0xFFF1F5F9);
}

/// Breakpoint-aware helper for the three canonical shell layouts.
enum ShellLayout { compact, medium, expanded }

ShellLayout shellLayoutFor(double width) {
  if (width >= 1200) return ShellLayout.expanded;
  if (width >= 600) return ShellLayout.medium;
  return ShellLayout.compact;
}
