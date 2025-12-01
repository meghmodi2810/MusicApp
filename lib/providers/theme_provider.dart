import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppColorScheme _colorScheme = AppColorScheme.warmYellow;
  bool _reduceAnimations = false; // NEW: Animation preference
  
  AppColorScheme get colorScheme => _colorScheme;
  ThemeData get theme => AppTheme.getTheme(_colorScheme);
  bool get isDarkMode => AppTheme.isDarkScheme(_colorScheme);
  Color get primaryColor => AppTheme.getAccentColor(_colorScheme);
  Color get backgroundColor => AppTheme.getBackgroundColor(_colorScheme);
  Color get cardColor => AppTheme.getCardColor(_colorScheme);
  Color get textColor => AppTheme.getTextColor(_colorScheme);
  Color get secondaryTextColor => AppTheme.getSecondaryTextColor(_colorScheme);
  Color get navBarColor => AppTheme.getNavBarColor(_colorScheme);
  bool get reduceAnimations => _reduceAnimations; // NEW: Getter for animation preference

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeIndex = prefs.getInt('colorScheme') ?? 0;
    _colorScheme = AppColorScheme.values[schemeIndex.clamp(0, AppColorScheme.values.length - 1)];
    _reduceAnimations = prefs.getBool('reduceAnimations') ?? true; // Changed default to TRUE
    notifyListeners();
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    _colorScheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorScheme', scheme.index);
    notifyListeners();
  }

  // NEW: Toggle animation preference
  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduceAnimations', value);
    notifyListeners();
  }

  // NEW: Get animation duration based on preference
  Duration getAnimationDuration(Duration normal) {
    return _reduceAnimations ? Duration.zero : normal;
  }

  String getSchemeName(AppColorScheme scheme) {
    return AppTheme.getSchemeName(scheme);
  }

  Color getSchemePreviewColor(AppColorScheme scheme) {
    return AppTheme.getSchemePreviewColor(scheme);
  }

  List<AppColorScheme> get availableSchemes => AppColorScheme.values;
}
