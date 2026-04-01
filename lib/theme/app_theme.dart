import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const background = Color(0xFFF5F0EB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0E8DE);
  static const navBar = Color(0xFFF0EBE4);
  static const navActive = Color(0xFF3D3426);
  static const navActiveBg = Color(0xFFD4C4A8);
  static const navInactive = Color(0xFFA09890);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB0A89E);
  static const primary = Color(0xFFC4A265);
  static const primaryLight = Color(0xFFD4C4A8);
  static const urgent = Color(0xFFD64B4B);
  static const urgentBg = Color(0xFFF0D4CF);
  static const warning = Color(0xFFE8A34E);
  static const warningBg = Color(0xFFF5E6D0);
  static const safe = Color(0xFF5D9D63);
  static const safeBg = Color(0xFFE2EFE3);
  static const success = Color(0xFF6BAF73);
  static const criticalCardBg = Color(0xFFF6EBE9);
  static const chipBg = Color(0xFFF0E8DE);
  static const chipText = Color(0xFF5A5248);
  static const expiryUseByBg = Color(0xFFEBCDC8);
  static const expiryUseByText = Color(0xFF8B4044);
  static const expiryBestBeforeBg = Color(0xFFE8DDD3);
  static const expiryBestBeforeText = Color(0xFF6B5F52);
  static const border = Color(0xFFE8E0D8);
  static const divider = Color(0xFFE8E0D8);
  static const inputBg = Color(0xFFF8F5F2);
  static const inputBorder = Color(0xFFE0D8CE);
  static const fab = Color(0xFFC8B48C);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.urgent,
      ),
      textTheme: base.copyWith(
        headlineLarge: base.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleLarge: base.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
        bodySmall: base.bodySmall?.copyWith(color: AppColors.textSecondary),
        labelLarge: base.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelMedium: base.labelMedium?.copyWith(color: AppColors.chipText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        titleTextStyle: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.chipText, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 0),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.fab,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
