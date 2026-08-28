import 'package:flutter/material.dart';

/// Pixel-Perfect Color Palette Matching Figma Design
class AppColors {
  AppColors._();

  // --- BRAND / PRIMARY TOKENS ---
  static const Color primaryDark = Color(0xFF0F172A);  // Slate 900 / Pure Dark
  static const Color primaryLight = Color(0xFF0F172A); // Slate 900
  static const Color accentBlue = Color(0xFF2563EB);   // Blue 600

  // --- BACKGROUND & SURFACE TOKENS ---
  static const Color bgLight = Color(0xFFFFFFFF);      // Pure White Background
  static const Color bgDark = Color(0xFF121316);       // Clean Neutral Dark Slate (Zero Pure Black, Zero Purple)

  static const Color cardLight = Color(0xFFF8FAFC);    // Figma Soft Card Surface (#F8FAFC / #F1F5F9)
  static const Color cardDark = Color(0xFF1C1D22);     // Soft Neutral Dark Card Surface

  static const Color pillLight = Color(0xFFF1F5F9);    // Figma Pill Surface (#F1F5F9)
  static const Color pillDark = Color(0xFF27282F);     // Clean Neutral Dark Pill Surface

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF18191E);

  static const Color surfaceVariantLight = Color(0xFFF8FAFC);
  static const Color surfaceVariantDark = Color(0xFF22232A);

  static const Color borderLight = Color(0xFFE2E8F0);  // Slate 200
  static const Color borderDark = Color(0xFF2E3039);   // Subtle Neutral Divider (Zero Purple)

  // --- TEXT TOKENS ---
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Slate 900 (#0F172A)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);    // Slate 50

  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500 (#64748B)
  static const Color textSecondaryDark = Color(0xFF94A3B8);  // Slate 400

  static const Color textMutedLight = Color(0xFF94A3B8);     // Slate 400 (#94A3B8)
  static const Color textMutedDark = Color(0xFF64748B);      // Slate 500

  // --- FIGMA ACTION BUTTON & STATUS TOKENS ---
  // Present / Emerald Green
  static const Color presentGreen = Color(0xFF10B981);          // Emerald 500 (#10B981)
  static const Color presentGreenLight = Color(0xFF10B981);
  static const Color presentGreenDark = Color(0xFF34D399);
  static const Color presentGreenText = Color(0xFF059669);      // Emerald 600 (#059669)
  static const Color presentContainerLight = Color(0xFFE6F7F0); // Soft Mint Pill (#E6F7F0)
  static const Color presentContainerDark = Color(0xFF064E3B);

  // Absent / Coral Rose Red
  static const Color absentRed = Color(0xFFEF4444);             // Red 500 (#EF4444)
  static const Color absentRedLight = Color(0xFFEF4444);
  static const Color absentRedDark = Color(0xFFFB7185);
  static const Color absentRedText = Color(0xFFDC2626);         // Red 600 (#DC2626)
  static const Color absentContainerLight = Color(0xFFFEE2E2);  // Soft Rose Pill (#FEE2E2)
  static const Color absentContainerDark = Color(0xFF4C0519);

  // Cancelled / Lavender Violet
  static const Color cancelledViolet = Color(0xFF8B5CF6);       // Violet 500 (#8B5CF6)
  static const Color cancelledVioletLight = Color(0xFF8B5CF6);
  static const Color cancelledVioletDark = Color(0xFFA78BFA);
  static const Color cancelledVioletText = Color(0xFF7C3AED);   // Violet 600 (#7C3AED)
  static const Color cancelledContainerLight = Color(0xFFEDE9FE);// Soft Lavender Pill (#EDE9FE)
  static const Color cancelledContainerDark = Color(0xFF2E1065);

  // Safe Badge
  static const Color safeBadgeBg = Color(0xFFE6F8F2);           // Figma Safe Badge Background
  static const Color safeBadgeText = Color(0xFF00A86B);         // Figma Safe Badge Text

  // Warning Amber
  static const Color warningAmberLight = Color(0xFFF59E0B);
  static const Color warningAmberDark = Color(0xFFFBBF24);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF451A03);

  // Accent Colors for Subjects
  static const Color accentIndigoLight = Color(0xFF4F46E5);
  static const Color accentIndigoDark = Color(0xFF818CF8);

  static Color getCategoryBg(String category, bool isDark) {
    if (isDark) {
      return const Color(0xFF27272A);
    }
    return const Color(0xFFF1F5F9);
  }

  static Color getCategoryText(String category, bool isDark) {
    if (isDark) {
      return const Color(0xFFE2E8F0);
    }
    return const Color(0xFF475569);
  }
}
