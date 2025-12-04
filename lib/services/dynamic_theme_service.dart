import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service to extract dominant colors from album art for dynamic theming
class DynamicThemeService {
  /// Cache for extracted palettes to avoid re-processing same images
  static final Map<String, PaletteGenerator> _paletteCache = {};

  /// Extract color palette from an album art URL
  static Future<DynamicThemeColors?> extractColorsFromAlbumArt(
    String? albumArtUrl,
    bool isDarkMode,
  ) async {
    if (albumArtUrl == null || albumArtUrl.isEmpty) {
      return null;
    }

    try {
      // Check cache first
      if (_paletteCache.containsKey(albumArtUrl)) {
        return _generateThemeFromPalette(
          _paletteCache[albumArtUrl]!,
          isDarkMode,
        );
      }

      // Load image from network
      final imageProvider = CachedNetworkImageProvider(albumArtUrl);

      // Generate palette
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      // Cache the palette
      _paletteCache[albumArtUrl] = palette;

      return _generateThemeFromPalette(palette, isDarkMode);
    } catch (e) {
      debugPrint('❌ Error extracting colors from album art: $e');
      return null;
    }
  }

  /// Generate theme colors from extracted palette
  static DynamicThemeColors _generateThemeFromPalette(
    PaletteGenerator palette,
    bool isDarkMode,
  ) {
    // Get the most vibrant color for accent
    Color accentColor =
        palette.vibrantColor?.color ??
        palette.lightVibrantColor?.color ??
        palette.dominantColor?.color ??
        const Color(0xFFFF6B6B);

    // Make sure accent is vibrant enough
    accentColor = _ensureVibrant(accentColor, isDarkMode);

    if (isDarkMode) {
      // Dark theme generation
      return DynamicThemeColors(
        background: const Color(0xFF000000), // Pure black for AMOLED
        card: _getDarkCardColor(palette),
        accent: accentColor,
        text: const Color(0xFFFFFFFF),
        secondaryText: const Color(0xB3FFFFFF),
        navBar: _getDarkNavBarColor(palette),
      );
    } else {
      // Light theme generation
      return DynamicThemeColors(
        background: _getLightBackgroundColor(palette),
        card: Colors.white,
        accent: accentColor,
        text: _getLightTextColor(palette),
        secondaryText: _getLightTextColor(palette).withOpacity(0.7),
        navBar: _getLightNavBarColor(palette),
      );
    }
  }

  /// Ensure the color is vibrant enough for accent
  static Color _ensureVibrant(Color color, bool isDarkMode) {
    final hsl = HSLColor.fromColor(color);

    // For dark mode, make colors brighter and more saturated
    if (isDarkMode) {
      return hsl
          .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
          .withLightness((hsl.lightness * 1.3).clamp(0.4, 0.7))
          .toColor();
    } else {
      // For light mode, keep colors punchy but not too bright
      return hsl
          .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
          .withLightness(hsl.lightness.clamp(0.3, 0.6))
          .toColor();
    }
  }

  /// Get dark card color from palette
  static Color _getDarkCardColor(PaletteGenerator palette) {
    final darkMuted = palette.darkMutedColor?.color;
    if (darkMuted != null) {
      return Color.lerp(darkMuted, Colors.black, 0.7) ??
          const Color(0xFF1A1A1A);
    }
    return const Color(0xFF1A1A1A);
  }

  /// Get dark navigation bar color
  static Color _getDarkNavBarColor(PaletteGenerator palette) {
    final darkColor =
        palette.darkMutedColor?.color ?? palette.darkVibrantColor?.color;
    if (darkColor != null) {
      return Color.lerp(darkColor, Colors.black, 0.6) ??
          const Color(0xFF1A1A1A);
    }
    return const Color(0xFF1A1A1A);
  }

  /// Get light background color from palette
  static Color _getLightBackgroundColor(PaletteGenerator palette) {
    final lightMuted = palette.lightMutedColor?.color;
    if (lightMuted != null) {
      // Make it very light and subtle
      return Color.lerp(lightMuted, Colors.white, 0.7) ?? Colors.white;
    }
    return Colors.white;
  }

  /// Get light text color
  static Color _getLightTextColor(PaletteGenerator palette) {
    final darkMuted = palette.darkMutedColor?.color;
    if (darkMuted != null) {
      return darkMuted;
    }
    return const Color(0xFF212121);
  }

  /// Get light navigation bar color
  static Color _getLightNavBarColor(PaletteGenerator palette) {
    final dominant = palette.dominantColor?.color;
    if (dominant != null) {
      final hsl = HSLColor.fromColor(dominant);
      return hsl.withLightness(0.3).withSaturation(0.8).toColor();
    }
    return const Color(0xFF757575);
  }

  /// Clear the palette cache
  static void clearCache() {
    _paletteCache.clear();
  }
}

/// Model to hold dynamic theme colors
class DynamicThemeColors {
  final Color background;
  final Color card;
  final Color accent;
  final Color text;
  final Color secondaryText;
  final Color navBar;

  DynamicThemeColors({
    required this.background,
    required this.card,
    required this.accent,
    required this.text,
    required this.secondaryText,
    required this.navBar,
  });
}
