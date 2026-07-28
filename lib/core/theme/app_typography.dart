import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thang chữ theo chuẩn Material 3, đầy đủ 15 style.
/// Bản cũ bodyLarge=18/bodyMedium=16 làm UI trông "phóng to" không giống app;
/// đã siết về 16/14/12, heading gọn hơn, label rõ vai trò.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final base = GoogleFonts.nunitoTextTheme();

    return base.copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.35,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
    );
  }
}
