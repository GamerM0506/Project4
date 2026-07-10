import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    // 1. Dùng Inter làm Base (mặc định) cho toàn bộ 15 style của Material 3
    final baseTheme = GoogleFonts.interTextTheme();

    // 2. Ghi đè (Override) các thẻ Heading bằng Montserrat theo cấu hình
    return baseTheme.copyWith(
      // Headline XL
      displayLarge: GoogleFonts.montserrat(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 40,
        height: 48 / 40,
      ),
      // Headline LG
      displayMedium: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32,
        height: 40 / 32,
      ),
      // Headline LG Mobile
      displaySmall: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
      ),
      // Mở rộng thêm cho các Heading mặc định của Flutter (để AppBar, Title dùng chung)
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      // Headline MD
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      
      // Body & Labels (Giữ nguyên Inter nhưng custom kích thước)
      // Body LG
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      ),
      // Body MD
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      // Label MD
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        height: 20 / 14,
      ),
      // Label SM
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      ),
    );
  }
}
