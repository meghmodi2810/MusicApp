import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.defaultTheme;
  
  AppThemeMode get themeMode => _themeMode;
  ThemeData get theme => AppTheme.getTheme(_themeMode);
  bool get isDarkMode => AppTheme.isDarkMode(_themeMode);
  Color get primaryColor => AppTheme.getPrimaryColor(_themeMode);
  Color get backgroundColor => AppTheme.getBackgroundColor(_themeMode);
  Color get cardColor => AppTheme.getCardColor(_themeMode);
  Color get textColor => AppTheme.getTextColor(_themeMode);

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = AppThemeMode.values[themeIndex.clamp(0, AppThemeMode.values.length - 1)];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return 'Default (Spotify)';
      case AppThemeMode.pixelated:
        return 'Pixelated';
      case AppThemeMode.lite:
        return 'Lite';
    }
  }

  String getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return 'Dark theme with Spotify-like aesthetics';
      case AppThemeMode.pixelated:
        return 'Retro pixel art style with 8-bit feel';
      case AppThemeMode.lite:
        return 'Clean, minimal light theme';
    }
  }

  IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return Icons.dark_mode;
      case AppThemeMode.pixelated:
        return Icons.grid_4x4;
      case AppThemeMode.lite:
        return Icons.light_mode;
    }
  }
}
