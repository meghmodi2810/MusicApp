import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/dynamic_theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  AppColorScheme _colorScheme = AppColorScheme.warmYellow;

  // Dynamic theme colors (only used when dynamic theme is active)
  DynamicThemeColors? _dynamicColors;

  AppColorScheme get colorScheme => _colorScheme;
  ThemeData get theme => AppTheme.getTheme(_colorScheme);
  bool get isDarkMode => AppTheme.isDarkScheme(_colorScheme);
  bool get isDynamicTheme =>
      _colorScheme == AppColorScheme.dynamicLight ||
      _colorScheme == AppColorScheme.dynamicDark;

  // Get colors - use dynamic colors if dynamic theme is active
  Color get primaryColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.accent
      : AppTheme.getAccentColor(_colorScheme);

  Color get backgroundColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.background
      : AppTheme.getBackgroundColor(_colorScheme);

  Color get cardColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.card
      : AppTheme.getCardColor(_colorScheme);

  Color get textColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.text
      : AppTheme.getTextColor(_colorScheme);

  Color get secondaryTextColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.secondaryText
      : AppTheme.getSecondaryTextColor(_colorScheme);

  Color get navBarColor => isDynamicTheme && _dynamicColors != null
      ? _dynamicColors!.navBar
      : AppTheme.getNavBarColor(_colorScheme);

  // Animations are now always disabled for better performance
  bool get reduceAnimations => true;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeIndex = prefs.getInt('colorScheme') ?? 0;
    _colorScheme = AppColorScheme
        .values[schemeIndex.clamp(0, AppColorScheme.values.length - 1)];
    notifyListeners();
  }

  Future<void> setColorScheme(
    AppColorScheme scheme, {
    String? currentAlbumArt,
  }) async {
    final wasDynamicTheme = isDynamicTheme;
    final oldScheme = _colorScheme;

    _colorScheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorScheme', scheme.index);

    // If switching away from dynamic theme, clear dynamic colors
    if (!isDynamicTheme) {
      _dynamicColors = null;
      notifyListeners();
    }
    // If switching TO dynamic theme OR switching between dynamic light/dark
    else if (!wasDynamicTheme || oldScheme != scheme) {
      // CRITICAL FIX: Immediately extract colors for the new dynamic theme mode
      if (currentAlbumArt != null) {
        debugPrint('🔄 Switching dynamic theme mode, re-extracting colors...');
        await updateDynamicTheme(currentAlbumArt);
      } else {
        // No album art available yet, just notify to show defaults
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Update dynamic theme based on album art
  Future<void> updateDynamicTheme(String? albumArtUrl) async {
    // Only extract colors if dynamic theme is active
    if (!isDynamicTheme) return;

    try {
      debugPrint('🎨 Extracting colors from album art for dynamic theme...');

      final colors = await DynamicThemeService.extractColorsFromAlbumArt(
        albumArtUrl,
        _colorScheme == AppColorScheme.dynamicDark,
      );

      if (colors != null) {
        _dynamicColors = colors;
        debugPrint('✅ Dynamic theme updated with colors from album art');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating dynamic theme: $e');
    }
  }

  // Animation duration is always zero for performance
  Duration getAnimationDuration(Duration normal) {
    return Duration.zero;
  }

  String getSchemeName(AppColorScheme scheme) {
    return AppTheme.getSchemeName(scheme);
  }

  Color getSchemePreviewColor(AppColorScheme scheme) {
    return AppTheme.getSchemePreviewColor(scheme);
  }

  List<AppColorScheme> get availableSchemes => AppColorScheme.values;
}
