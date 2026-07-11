import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    // 1. Dùng Quicksand làm Base (mặc định) cho toàn bộ 15 style của Material 3
    final baseTheme = GoogleFonts.quicksandTextTheme();

    // 2. Ghi đè (Override) các thẻ Heading bằng Quicksand theo cấu hình
    return baseTheme.copyWith(
      // Headline XL
      displayLarge: GoogleFonts.quicksand(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 40,
        height: 48 / 40,
      ),
      // Headline LG
      displayMedium: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32,
        height: 40 / 32,
      ),
      // Headline LG Mobile
      displaySmall: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
      ),
      // Mở rộng thêm cho các Heading mặc định của Flutter (để AppBar, Title dùng chung)
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      // Headline MD
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      ),
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      
      // Body & Labels (Dùng Quicksand nhưng custom kích thước)
      // Body LG
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      ),
      // Body MD
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      // Label MD
      labelLarge: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        height: 20 / 14,
      ),
      // Label SM
      labelMedium: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      ),
    );
  }
}
