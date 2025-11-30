import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppColorScheme _colorScheme = AppColorScheme.warmYellow;
  
  AppColorScheme get colorScheme => _colorScheme;
  ThemeData get theme => AppTheme.getTheme(_colorScheme);
  bool get isDarkMode => AppTheme.isDarkScheme(_colorScheme);
  Color get primaryColor => AppTheme.getAccentColor(_colorScheme);
  Color get backgroundColor => AppTheme.getBackgroundColor(_colorScheme);
  Color get cardColor => AppTheme.getCardColor(_colorScheme);
  Color get textColor => AppTheme.getTextColor(_colorScheme);
  Color get secondaryTextColor => AppTheme.getSecondaryTextColor(_colorScheme);
  Color get navBarColor => AppTheme.getNavBarColor(_colorScheme);

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeIndex = prefs.getInt('colorScheme') ?? 0;
    _colorScheme = AppColorScheme.values[schemeIndex.clamp(0, AppColorScheme.values.length - 1)];
    notifyListeners();
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    _colorScheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorScheme', scheme.index);
    notifyListeners();
  }

  String getSchemeName(AppColorScheme scheme) {
    return AppTheme.getSchemeName(scheme);
  }

  Color getSchemePreviewColor(AppColorScheme scheme) {
    return AppTheme.getSchemePreviewColor(scheme);
  }

  List<AppColorScheme> get availableSchemes => AppColorScheme.values;
}
