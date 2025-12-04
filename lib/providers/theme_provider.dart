import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/dynamic_theme_service.dart';
import 'dart:convert'; // For JSON encoding/decoding

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

    // NEW: Load cached dynamic theme colors if using dynamic theme
    if (isDynamicTheme) {
      await _loadCachedDynamicColors();
    }

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

    // If switching away from dynamic theme, clear dynamic colors and cache
    if (!isDynamicTheme) {
      _dynamicColors = null;
      await _clearCachedDynamicColors(); // Clear cache
      notifyListeners();
    }
    // If switching TO dynamic theme OR switching between dynamic light/dark
    else if (!wasDynamicTheme || oldScheme != scheme) {
      // First, try to load cached colors
      await _loadCachedDynamicColors();

      // Then extract new colors if album art is available
      if (currentAlbumArt != null) {
        debugPrint('🔄 Switching dynamic theme mode, re-extracting colors...');
        await updateDynamicTheme(currentAlbumArt);
      } else {
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

        // NEW: Cache the extracted colors
        await _cacheDynamicColors(colors);

        debugPrint('✅ Dynamic theme updated with colors from album art');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating dynamic theme: $e');
    }
  }

  /// Save dynamic theme colors to cache
  Future<void> _cacheDynamicColors(DynamicThemeColors colors) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save colors as JSON
      final colorData = {
        'background': colors.background.value,
        'card': colors.card.value,
        'accent': colors.accent.value,
        'text': colors.text.value,
        'secondaryText': colors.secondaryText.value,
        'navBar': colors.navBar.value,
        'isDark': _colorScheme == AppColorScheme.dynamicDark,
      };

      await prefs.setString('cached_dynamic_colors', json.encode(colorData));
      debugPrint('💾 Cached dynamic theme colors');
    } catch (e) {
      debugPrint('❌ Error caching dynamic colors: $e');
    }
  }

  /// Load cached dynamic theme colors
  Future<void> _loadCachedDynamicColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_dynamic_colors');

      if (cachedData != null) {
        final colorData = json.decode(cachedData) as Map<String, dynamic>;

        // Check if cached colors match current dynamic theme mode (light/dark)
        final cachedIsDark = colorData['isDark'] as bool? ?? false;
        final currentIsDark = _colorScheme == AppColorScheme.dynamicDark;

        if (cachedIsDark == currentIsDark) {
          _dynamicColors = DynamicThemeColors(
            background: Color(colorData['background'] as int),
            card: Color(colorData['card'] as int),
            accent: Color(colorData['accent'] as int),
            text: Color(colorData['text'] as int),
            secondaryText: Color(colorData['secondaryText'] as int),
            navBar: Color(colorData['navBar'] as int),
          );
          debugPrint('✅ Loaded cached dynamic theme colors');
        } else {
          debugPrint('⚠️ Cached colors don\'t match current mode, skipping');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading cached dynamic colors: $e');
    }
  }

  /// Clear cached dynamic theme colors
  Future<void> _clearCachedDynamicColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_dynamic_colors');
      debugPrint('🗑️ Cleared cached dynamic theme colors');
    } catch (e) {
      debugPrint('❌ Error clearing cached colors: $e');
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
