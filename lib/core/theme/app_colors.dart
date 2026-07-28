import 'package:flutter/material.dart';

/// Palette đã tinh chỉnh quanh brand đỏ #AE2F34.
/// - primaryContainer dùng tonal rose nhạt (#FFDAD6) thay #FF6B6B gắt
/// - surface ramp trung tính ấm, để đỏ làm điểm nhấn
/// - tertiary đổi từ vàng-olive sang amber ấm cho sang hơn
/// - Thêm semantic colors cho badge trạng thái (pending/approved/...)
class AppColors {
  AppColors._();

  static const Color brand = Color(0xFFAE2F34);

  // ---- Semantic (light) ----
  static const Color success = Color(0xFF1B8A5A);
  static const Color successContainer = Color(0xFFBCF2D8);
  static const Color onSuccessContainer = Color(0xFF00391F);
  static const Color warning = Color(0xFF945A00);
  static const Color warningContainer = Color(0xFFFFE2AC);
  static const Color onWarningContainer = Color(0xFF3E2700);
  static const Color info = Color(0xFF00677C);
  static const Color infoContainer = Color(0xFFB1EBFF);
  static const Color onInfoContainer = Color(0xFF00323E);

  // ---- Semantic (dark) ----
  static const Color successDark = Color(0xFF6FDAA4);
  static const Color successContainerDark = Color(0xFF005234);
  static const Color onSuccessContainerDark = Color(0xFFBCF2D8);
  static const Color warningDark = Color(0xFFF0BF6B);
  static const Color warningContainerDark = Color(0xFF5A3B00);
  static const Color onWarningContainerDark = Color(0xFFFFE2AC);
  static const Color infoDark = Color(0xFF86D1E8);
  static const Color infoContainerDark = Color(0xFF004E5E);
  static const Color onInfoContainerDark = Color(0xFFB1EBFF);

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFAE2F34),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF680011),
    secondary: Color(0xFF006A65),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF9CF1EA),
    onSecondaryContainer: Color(0xFF00201E),
    tertiary: Color(0xFF8A5100),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDCBD),
    onTertiaryContainer: Color(0xFF2C1600),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFCFBFA),
    onSurface: Color(0xFF1B1C1C),
    surfaceDim: Color(0xFFE3E0DF),
    surfaceBright: Color(0xFFFCFBFA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F5F3),
    surfaceContainer: Color(0xFFF1EFED),
    surfaceContainerHigh: Color(0xFFEBE9E7),
    surfaceContainerHighest: Color(0xFFE5E3E1),
    onSurfaceVariant: Color(0xFF5B5452),
    outline: Color(0xFF9A8F8D),
    outlineVariant: Color(0xFFE8E3E1),
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Color(0xFFF3F0F0),
    inversePrimary: Color(0xFFFFB3AC),
    surfaceTint: Color(0xFFAE2F34),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF8A83),
    onPrimary: Color(0xFF5C1018),
    primaryContainer: Color(0xFF8C1520),
    onPrimaryContainer: Color(0xFFFFDAD6),
    secondary: Color(0xFF4CDAD0),
    onSecondary: Color(0xFF003734),
    secondaryContainer: Color(0xFF00504C),
    onSecondaryContainer: Color(0xFF9CF1EA),
    tertiary: Color(0xFFF0BE78),
    onTertiary: Color(0xFF4A2800),
    tertiaryContainer: Color(0xFF693C00),
    onTertiaryContainer: Color(0xFFFFDCBD),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF161312),
    onSurface: Color(0xFFEDE6E4),
    surfaceDim: Color(0xFF161312),
    surfaceBright: Color(0xFF3C3837),
    surfaceContainerLowest: Color(0xFF100E0D),
    surfaceContainerLow: Color(0xFF1E1B1A),
    surfaceContainer: Color(0xFF221F1E),
    surfaceContainerHigh: Color(0xFF2D2A29),
    surfaceContainerHighest: Color(0xFF383434),
    onSurfaceVariant: Color(0xFFCFC5C3),
    outline: Color(0xFF9A8F8D),
    outlineVariant: Color(0xFF48403E),
    inverseSurface: Color(0xFFEDE6E4),
    onInverseSurface: Color(0xFF343030),
    inversePrimary: Color(0xFFAE2F34),
    surfaceTint: Color(0xFFFF8A83),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}
