import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return GoogleFonts.notoSansTextTheme().copyWith(
      // Display
      displayLarge: _style(32, FontWeight.w700),
      displayMedium: _style(28, FontWeight.w700),
      displaySmall: _style(24, FontWeight.w700),

      // Headline
      headlineLarge: _style(24, FontWeight.w700),
      headlineMedium: _style(20, FontWeight.w600),
      headlineSmall: _style(18, FontWeight.w600),

      // Title
      titleLarge: _style(18, FontWeight.w700),
      titleMedium: _style(16, FontWeight.w600),
      titleSmall: _style(14, FontWeight.w600),

      // Body
      bodyLarge: _style(16, FontWeight.w400),
      bodyMedium: _style(14, FontWeight.w400),
      bodySmall: _style(12, FontWeight.w400),

      // Label
      labelLarge: _style(14, FontWeight.w600),
      labelMedium: _style(12, FontWeight.w500),
      labelSmall: _style(11, FontWeight.w500),
    );
  }

  static TextStyle _style(double size, FontWeight weight) {
    return GoogleFonts.notoSans(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.textPrimary,
      height: 1.5,
    );
  }

  // Convenience styles (Noto Sans)
  static TextStyle get amountLarge => _style(28, FontWeight.w700);
  static TextStyle get amountMedium => _style(22, FontWeight.w700);
  static TextStyle get amountSmall => _style(16, FontWeight.w600);

  static TextStyle get hint =>
      _style(12, FontWeight.w400).copyWith(color: AppColors.textHint);

  static TextStyle get caption =>
      _style(12, FontWeight.w400).copyWith(color: AppColors.textSecondary);

  // Number display styles (Manrope — crisp, fintech-grade numerals)
  static TextStyle _numStyle(double size, FontWeight weight) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.textPrimary,
      height: 1.2,
    );
  }

  static TextStyle get numDisplayLarge =>
      _numStyle(32, FontWeight.w800);
  static TextStyle get numDisplayMedium =>
      _numStyle(24, FontWeight.w700);
  static TextStyle get numBody =>
      _numStyle(16, FontWeight.w600);
  static TextStyle get numBodySmall =>
      _numStyle(14, FontWeight.w500);
}
