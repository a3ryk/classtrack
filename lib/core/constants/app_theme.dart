import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Ultra-Minimalist Production Theme Architecture
class AppTheme {
  AppTheme._();

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceVariantLight,
      onPrimaryContainer: AppColors.textPrimaryLight,
      secondary: AppColors.accentIndigoLight,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      error: AppColors.absentRedLight,
      onError: Colors.white,
      outline: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight, size: 20),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.cardLight,
        headerForegroundColor: AppColors.textPrimaryLight,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.textMutedLight;
          return AppColors.textPrimaryLight;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.textPrimaryLight;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.accentIndigoLight;
        }),
        todayBorder: const BorderSide(color: AppColors.accentIndigoLight),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accentIndigoLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.cardLight,
        hourMinuteTextColor: AppColors.textPrimaryLight,
        hourMinuteColor: const Color(0xFFF1F5F9),
        dayPeriodTextColor: AppColors.textPrimaryLight,
        dayPeriodColor: const Color(0xFFF1F5F9),
        dialHandColor: AppColors.textPrimaryLight,
        dialBackgroundColor: const Color(0xFFF1F5F9),
        dialTextColor: AppColors.textPrimaryLight,
        entryModeIconColor: AppColors.textPrimaryLight,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accentIndigoLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.textPrimaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(
          color: AppColors.textMutedLight,
          fontSize: 13.5,
          fontWeight: FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textPrimaryLight, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.textPrimaryLight,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Neutral Dark Theme Configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.textPrimaryDark,
      onPrimary: AppColors.bgDark,
      primaryContainer: AppColors.surfaceVariantDark,
      onPrimaryContainer: AppColors.textPrimaryDark,
      secondary: AppColors.accentIndigoDark,
      onSecondary: AppColors.bgDark,
      surface: AppColors.cardDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      error: AppColors.absentRedDark,
      onError: Colors.black,
      outline: AppColors.borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _buildTextTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark, size: 20),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.cardDark,
        headerForegroundColor: AppColors.textPrimaryDark,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.bgDark;
          if (states.contains(WidgetState.disabled)) return AppColors.textMutedDark;
          return AppColors.textPrimaryDark;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.textPrimaryDark;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.bgDark;
          return AppColors.accentIndigoDark;
        }),
        todayBorder: const BorderSide(color: AppColors.accentIndigoDark),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accentIndigoDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.cardDark,
        hourMinuteTextColor: AppColors.textPrimaryDark,
        hourMinuteColor: AppColors.surfaceDark,
        dayPeriodTextColor: AppColors.textPrimaryDark,
        dayPeriodColor: AppColors.surfaceDark,
        dialHandColor: AppColors.textPrimaryDark,
        dialBackgroundColor: AppColors.surfaceDark,
        dialTextColor: AppColors.textPrimaryDark,
        entryModeIconColor: AppColors.textPrimaryDark,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accentIndigoDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.textPrimaryDark,
          foregroundColor: AppColors.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: const TextStyle(
          color: AppColors.textMutedDark,
          fontSize: 13.5,
          fontWeight: FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textPrimaryDark, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDark,
        selectedItemColor: AppColors.textPrimaryDark,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: primaryText, letterSpacing: -0.5),
      displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: primaryText, letterSpacing: -0.5),
      displaySmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: primaryText),
      headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: primaryText),
      headlineMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: primaryText),
      headlineSmall: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
      titleLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: secondaryText),
      bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: primaryText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: primaryText),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: secondaryText),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryText),
    );
  }
}
