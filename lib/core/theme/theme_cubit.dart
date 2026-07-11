import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themePrefKey = 'theme_mode';
  final SharedPreferences prefs;

  ThemeCubit({required this.prefs}) : super(_getThemeModeFromPrefs(prefs));

  static ThemeMode _getThemeModeFromPrefs(SharedPreferences prefs) {
    final themeString = prefs.getString(_themePrefKey);
    if (themeString == 'light') return ThemeMode.light;
    if (themeString == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void updateTheme(ThemeMode mode) {
    emit(mode); // Emit immediately for smooth UI transition
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    prefs.setString(_themePrefKey, themeString);
  }
}
