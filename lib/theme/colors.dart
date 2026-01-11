import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient
  static const Color primaryStart = Color(0xFF6366F1);
  static const Color primaryEnd = Color(0xFF8B5CF6);
  
  // Secondary Gradient  
  static const Color secondaryStart = Color(0xFFEC4899);
  static const Color secondaryEnd = Color(0xFFF97316);
  
  // Status Colors
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // ============ DARK THEME ============
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF334155);
  static const Color borderLight = Color(0xFF475569);
  
  // ============ LIGHT THEME ============
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLightGray = Color(0xFFE2E8F0);
  static const Color textPrimaryDark = Color(0xFF0F172A);
  static const Color textSecondaryDark = Color(0xFF475569);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderLightTheme = Color(0xFFCBD5E1);
  static const Color borderLightGray = Color(0xFFE2E8F0);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryEnd],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryStart, secondaryEnd],
  );
  
  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF0F172A),
    ],
  );
  
  static const LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF1F5F9),
      Color(0xFFE0E7FF),
      Color(0xFFF1F5F9),
    ],
  );
}
