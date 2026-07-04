import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// ChefSync Enterprise design language.
///
/// Public API (colors + lightTheme/darkTheme) is intentionally unchanged
/// so every existing screen that references `AppTheme.primaryColor`,
/// `AppTheme.secondaryColor`, `AppTheme.backgroundColorLight`,
/// `AppTheme.cardColorLight` or `AppTheme.errorColor` keeps working with
/// zero edits. Only the *values* and the component theming underneath
/// were refined, plus a handful of new tokens were added for the
/// redesigned screens to reach for.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Brand palette — "Ink & Emerald"
  // A cool, editorial ink (not pure slate-800 off the shelf) paired with
  // a slightly deeper, less-saccharine emerald than the seed default.
  // This is the pairing every redesigned screen is built around.
  // ---------------------------------------------------------------------
  static const Color primaryColor = Color(0xFF0EA371); // Emerald 600, deepened
  static const Color primaryColorDark = Color(0xFF0B7A56);
  static const Color secondaryColor = Color(0xFF14213D); // Ink, not stock slate-800
  static const Color backgroundColorLight = Color(0xFFF7F8FA);
  static const Color cardColorLight = Colors.white;
  static const Color errorColor = Color(0xFFDC2626);

  // Text hierarchy — three named tiers instead of ad-hoc grey.shadeNNN
  // scattered through widgets.
  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textTertiary = Color(0xFF94A0AF);
  static const Color borderColor = Color(0xFFE7EAEE);
  static const Color borderColorStrong = Color(0xFFD6DAE1);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12B886), Color(0xFF0B7A56)],
  );

  static const LinearGradient inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2B4D), Color(0xFF0B1120)],
  );

  static TextTheme _typeScale(TextTheme base, Color heading, Color body) {
    // Space Grotesk for anything a user scans (headings, numbers, KPIs) —
    // it has a slightly geometric, technical character that reads as
    // "product", not "marketing site". Inter for everything read at
    // length (labels, body, table cells) because it's built for UI.
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 40, fontWeight: FontWeight.w700, color: heading, letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w700, color: heading, letterSpacing: -0.6,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 26, fontWeight: FontWeight.w700, color: heading, letterSpacing: -0.4,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22, fontWeight: FontWeight.w600, color: heading, letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w600, color: heading,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, color: heading,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: body, height: 1.45),
      bodyMedium: GoogleFonts.inter(fontSize: 13.5, color: body, height: 1.45),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: body, height: 1.4),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: heading, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: body, letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10.5, fontWeight: FontWeight.w700, color: body, letterSpacing: 0.6,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColorLight,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1, space: 1),
      textTheme: _typeScale(ThemeData.light().textTheme, textPrimary, textSecondary),
      cardTheme: CardThemeData(
        color: cardColorLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFCFD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: errorColor, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: borderColorStrong),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        side: BorderSide.none,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: secondaryColor),
        titleTextStyle: null,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withOpacity(0.12),
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: textTertiary),
        selectedLabelTextStyle: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: GoogleFonts.inter(color: textTertiary, fontWeight: FontWeight.w500, fontSize: 12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: AppRadius.smRadius,
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondaryColor,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: Colors.amber,
        surface: const Color(0xFF0F172A),
        error: errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      textTheme: _typeScale(ThemeData.dark().textTheme, Colors.white, const Color(0xFFB6BFCC)),
      cardTheme: CardThemeData(
        color: const Color(0xFF161F32),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: Color(0xFF283349), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
