import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    // 1. Dùng Nunito làm Base (mặc định) cho toàn bộ 15 style của Material 3
    final baseTheme = GoogleFonts.nunitoTextTheme();

    // 2. Ghi đè (Override) các thẻ Heading bằng Nunito theo cấu hình
    return baseTheme.copyWith(
      // Headline XL
      displayLarge: GoogleFonts.nunito(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 40,
        height: 48 / 40,
      ),
      // Headline LG
      displayMedium: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32,
        height: 40 / 32,
      ),
      // Headline LG Mobile
      displaySmall: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
      ),
      // Mở rộng thêm cho các Heading mặc định của Flutter (để AppBar, Title dùng chung)
      headlineLarge: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      // Headline MD
      headlineMedium: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      
      // Body & Labels (Dùng Nunito nhưng custom kích thước)
      // Body LG
      bodyLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      ),
      // Body MD
      bodyMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      // Label MD
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        height: 20 / 14,
      ),
      // Label SM
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      ),
    );
  }
}
