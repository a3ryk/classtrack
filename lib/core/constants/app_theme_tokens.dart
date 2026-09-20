import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeExtension providing unified tokens across both Classic and Cute themes
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final String themeStyleId;
  final bool isCute;
  final Color scaffoldBg;
  final Color cardBg;
  final Color cardBorder;
  final double cardRadius;
  final double buttonRadius;
  final double sheetRadius;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color presentColor;
  final Color presentContainer;
  final Color absentColor;
  final Color absentContainer;
  final Color cancelledColor;
  final Color cancelledContainer;
  final Color safeBadgeBg;
  final Color safeBadgeText;
  final Color navBgColor;
  final Color navActivePillColor;
  final Color navPillBorderColor;
  final Color navBorderColor;
  final Color navActiveTextColor;
  final Color navInactiveTextColor;
  final Color navActiveIconColor;
  final Color navInactiveIconColor;
  final Color navShadowColor;

  const AppThemeTokens({
    required this.themeStyleId,
    required this.isCute,
    required this.scaffoldBg,
    required this.cardBg,
    required this.cardBorder,
    required this.cardRadius,
    required this.buttonRadius,
    required this.sheetRadius,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.presentColor,
    required this.presentContainer,
    required this.absentColor,
    required this.absentContainer,
    required this.cancelledColor,
    required this.cancelledContainer,
    required this.safeBadgeBg,
    required this.safeBadgeText,
    required this.navBgColor,
    required this.navActivePillColor,
    required this.navPillBorderColor,
    required this.navBorderColor,
    required this.navActiveTextColor,
    required this.navInactiveTextColor,
    required this.navActiveIconColor,
    required this.navInactiveIconColor,
    required this.navShadowColor,
  });

  /// Classic Light (Authentic Figma Tokens)
  static const AppThemeTokens classicLight = AppThemeTokens(
    themeStyleId: 'classic_indigo',
    isCute: false,
    scaffoldBg: AppColors.bgLight,
    cardBg: Colors.white,
    cardBorder: AppColors.borderLight,
    cardRadius: 12.0,
    buttonRadius: 8.0,
    sheetRadius: 14.0,
    primaryAccent: AppColors.accentIndigoLight,
    secondaryAccent: AppColors.accentBlue,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    presentColor: AppColors.presentGreen,
    presentContainer: AppColors.presentContainerLight,
    absentColor: AppColors.absentRed,
    absentContainer: AppColors.absentContainerLight,
    cancelledColor: AppColors.cancelledViolet,
    cancelledContainer: AppColors.cancelledContainerLight,
    safeBadgeBg: AppColors.safeBadgeBg,
    safeBadgeText: AppColors.safeBadgeText,
    navBgColor: Color(0xFFFFFFFF),
    navActivePillColor: AppColors.pillLight,
    navPillBorderColor: AppColors.borderLight,
    navBorderColor: AppColors.borderLight,
    navActiveTextColor: AppColors.textPrimaryLight,
    navInactiveTextColor: AppColors.textSecondaryLight,
    navActiveIconColor: AppColors.textPrimaryLight,
    navInactiveIconColor: AppColors.textSecondaryLight,
    navShadowColor: Color(0x0A000000),
  );

  /// Classic Dark (Neutral Slate Tokens)
  static const AppThemeTokens classicDark = AppThemeTokens(
    themeStyleId: 'classic_indigo',
    isCute: false,
    scaffoldBg: AppColors.bgDark,
    cardBg: AppColors.cardDark,
    cardBorder: AppColors.borderDark,
    cardRadius: 12.0,
    buttonRadius: 8.0,
    sheetRadius: 14.0,
    primaryAccent: AppColors.accentIndigoDark,
    secondaryAccent: AppColors.accentBlue,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    presentColor: AppColors.presentGreenDark,
    presentContainer: Color(0xFF064E3B),
    absentColor: AppColors.absentRedDark,
    absentContainer: Color(0xFF4C0519),
    cancelledColor: AppColors.cancelledVioletDark,
    cancelledContainer: Color(0xFF2E1065),
    safeBadgeBg: Color(0xFF064E3B),
    safeBadgeText: Color(0xFF34D399),
    navBgColor: AppColors.bgDark,
    navActivePillColor: AppColors.pillDark,
    navPillBorderColor: AppColors.borderDark,
    navBorderColor: AppColors.borderDark,
    navActiveTextColor: AppColors.textPrimaryDark,
    navInactiveTextColor: AppColors.textSecondaryDark,
    navActiveIconColor: AppColors.textPrimaryDark,
    navInactiveIconColor: AppColors.textSecondaryDark,
    navShadowColor: Color(0x20000000),
  );

  /// Cute Sprout Light (Exact Sage Design Specification)
  static const AppThemeTokens cuteSproutLight = AppThemeTokens(
    themeStyleId: 'cute_sprout',
    isCute: true,
    scaffoldBg: Color(0xFFFAF7F2), // Marshmallow cream
    cardBg: Colors.white,
    cardBorder: Color(0xFFE4ECE0), // Soft sage outline
    cardRadius: 20.0,
    buttonRadius: 999.0, // Full pill buttons
    sheetRadius: 28.0,
    primaryAccent: Color(0xFF689F38), // Fresh sprout leaf green
    secondaryAccent: Color(0xFFFFAAA6), // Rosy cheek peach/pink
    textPrimary: Color(0xFF1E3526), // Deep woodland charcoal
    textSecondary: Color(0xFF5B7362), // Soft moss slate
    textMuted: Color(0xFF8BA392),
    presentColor: Color(0xFF4CAF50),
    presentContainer: Color(0xFFE8F5E9),
    absentColor: Color(0xFFFF6B81),
    absentContainer: Color(0xFFFFEBEE),
    cancelledColor: Color(0xFF9575CD),
    cancelledContainer: Color(0xFFEDE7F6),
    safeBadgeBg: Color(0xFFE8F5E9),
    safeBadgeText: Color(0xFF2E7D32),
    navBgColor: Color(0xFFFDFCF7), // Light Sage Navbar BG
    navActivePillColor: Color(0xFFEAF8E7), // Active Pill BG
    navPillBorderColor: Color(0xFFD7F0D6), // Pill Border (subtle)
    navBorderColor: Color(0xFFE7E5DC), // Navbar Border
    navActiveTextColor: Color(0xFF1E6B3F), // Label (Active)
    navInactiveTextColor: Color(0xFF6B8D7A), // Label (Inactive)
    navActiveIconColor: Color(0xFF1E6B3F), // Icon (Active)
    navInactiveIconColor: Color(0xFF6B8D7A), // Icon (Inactive)
    navShadowColor: Color(0x0D000000), // Shadow #0000000D
  );

  /// Cute Sprout Dark (Exact Sage Design Specification)
  static const AppThemeTokens cuteSproutDark = AppThemeTokens(
    themeStyleId: 'cute_sprout',
    isCute: true,
    scaffoldBg: Color(0xFF122419), // Deep moss forest canvas
    cardBg: Color(0xFF1B3626), // Woodland moss card
    cardBorder: Color(0xFF274C37), // Subtle emerald moss border
    cardRadius: 20.0,
    buttonRadius: 999.0,
    sheetRadius: 28.0,
    primaryAccent: Color(0xFF8BC34A), // Glowing sprout green
    secondaryAccent: Color(0xFFFF80AB), // Rosy cheek blush
    textPrimary: Color(0xFFF4F8F3), // Pale mint cream white
    textSecondary: Color(0xFFA3C2AC), // Silvery sage
    textMuted: Color(0xFF6E8D77),
    presentColor: Color(0xFF66BB6A),
    presentContainer: Color(0xFF143D24),
    absentColor: Color(0xFFFA7268),
    absentContainer: Color(0xFF3F141B),
    cancelledColor: Color(0xFFB39DDB),
    cancelledContainer: Color(0xFF2B1A40),
    safeBadgeBg: Color(0xFF143D24),
    safeBadgeText: Color(0xFF81C784),
    navBgColor: Color(0xFF0E2B1F), // Dark Sage Navbar BG
    navActivePillColor: Color(0xFF164130), // Active Pill BG
    navPillBorderColor: Color(0xFF2C5B45), // Pill Border (subtle)
    navBorderColor: Color(0xFF133628), // Navbar Border
    navActiveTextColor: Color(0xFFEAF8EA), // Label (Active)
    navInactiveTextColor: Color(0xFFA7BDB1), // Label (Inactive)
    navActiveIconColor: Color(0xFFA7F3A0), // Icon (Active)
    navInactiveIconColor: Color(0xFF8AA59A), // Icon (Inactive)
    navShadowColor: Color(0x33000000), // Shadow #00000033
  );

  @override
  ThemeExtension<AppThemeTokens> copyWith({
    String? themeStyleId,
    bool? isCute,
    Color? scaffoldBg,
    Color? cardBg,
    Color? cardBorder,
    double? cardRadius,
    double? buttonRadius,
    double? sheetRadius,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? presentColor,
    Color? presentContainer,
    Color? absentColor,
    Color? absentContainer,
    Color? cancelledColor,
    Color? cancelledContainer,
    Color? safeBadgeBg,
    Color? safeBadgeText,
    Color? navBgColor,
    Color? navActivePillColor,
    Color? navPillBorderColor,
    Color? navBorderColor,
    Color? navActiveTextColor,
    Color? navInactiveTextColor,
    Color? navActiveIconColor,
    Color? navInactiveIconColor,
    Color? navShadowColor,
  }) {
    return AppThemeTokens(
      themeStyleId: themeStyleId ?? this.themeStyleId,
      isCute: isCute ?? this.isCute,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      presentColor: presentColor ?? this.presentColor,
      presentContainer: presentContainer ?? this.presentContainer,
      absentColor: absentColor ?? this.absentColor,
      absentContainer: absentContainer ?? this.absentContainer,
      cancelledColor: cancelledColor ?? this.cancelledColor,
      cancelledContainer: cancelledContainer ?? this.cancelledContainer,
      safeBadgeBg: safeBadgeBg ?? this.safeBadgeBg,
      safeBadgeText: safeBadgeText ?? this.safeBadgeText,
      navBgColor: navBgColor ?? this.navBgColor,
      navActivePillColor: navActivePillColor ?? this.navActivePillColor,
      navPillBorderColor: navPillBorderColor ?? this.navPillBorderColor,
      navBorderColor: navBorderColor ?? this.navBorderColor,
      navActiveTextColor: navActiveTextColor ?? this.navActiveTextColor,
      navInactiveTextColor: navInactiveTextColor ?? this.navInactiveTextColor,
      navActiveIconColor: navActiveIconColor ?? this.navActiveIconColor,
      navInactiveIconColor: navInactiveIconColor ?? this.navInactiveIconColor,
      navShadowColor: navShadowColor ?? this.navShadowColor,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      themeStyleId: t < 0.5 ? themeStyleId : other.themeStyleId,
      isCute: t < 0.5 ? isCute : other.isCute,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardRadius: ui.lerpDouble(cardRadius, other.cardRadius, t)!,
      buttonRadius: ui.lerpDouble(buttonRadius, other.buttonRadius, t)!,
      sheetRadius: ui.lerpDouble(sheetRadius, other.sheetRadius, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      presentColor: Color.lerp(presentColor, other.presentColor, t)!,
      presentContainer: Color.lerp(presentContainer, other.presentContainer, t)!,
      absentColor: Color.lerp(absentColor, other.absentColor, t)!,
      absentContainer: Color.lerp(absentContainer, other.absentContainer, t)!,
      cancelledColor: Color.lerp(cancelledColor, other.cancelledColor, t)!,
      cancelledContainer: Color.lerp(cancelledContainer, other.cancelledContainer, t)!,
      safeBadgeBg: Color.lerp(safeBadgeBg, other.safeBadgeBg, t)!,
      safeBadgeText: Color.lerp(safeBadgeText, other.safeBadgeText, t)!,
      navBgColor: Color.lerp(navBgColor, other.navBgColor, t)!,
      navActivePillColor: Color.lerp(navActivePillColor, other.navActivePillColor, t)!,
      navPillBorderColor: Color.lerp(navPillBorderColor, other.navPillBorderColor, t)!,
      navBorderColor: Color.lerp(navBorderColor, other.navBorderColor, t)!,
      navActiveTextColor: Color.lerp(navActiveTextColor, other.navActiveTextColor, t)!,
      navInactiveTextColor: Color.lerp(navInactiveTextColor, other.navInactiveTextColor, t)!,
      navActiveIconColor: Color.lerp(navActiveIconColor, other.navActiveIconColor, t)!,
      navInactiveIconColor: Color.lerp(navInactiveIconColor, other.navInactiveIconColor, t)!,
      navShadowColor: Color.lerp(navShadowColor, other.navShadowColor, t)!,
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppThemeTokens.classicDark
          : AppThemeTokens.classicLight);
}
