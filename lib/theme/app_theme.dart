import 'package:flutter/material.dart';

// Color scheme options for the app
enum AppColorScheme {
  warmYellow,   // Default - like the image
  softPink,
  amoledBlack,
  mintGreen,
  lavender,
  peach,
}

class AppTheme {
  // Warm Yellow Theme Colors (Default - matching the image)
  static const Color warmYellow = Color(0xFFF5DEB3);
  static const Color warmYellowLight = Color(0xFFFAEBD7);
  static const Color warmOrange = Color(0xFFD2691E);
  static const Color warmBrown = Color(0xFF8B4513);
  static const Color warmRed = Color(0xFFCD5C5C);
  static const Color warmDarkBrown = Color(0xFF5D3A1A);
  
  // Soft Pink Theme Colors
  static const Color softPink = Color(0xFFFFE4E1);
  static const Color softPinkAccent = Color(0xFFFF69B4);
  static const Color softPinkDark = Color(0xFFDB7093);
  
  // AMOLED Black Theme Colors
  static const Color amoledBlack = Color(0xFF000000);
  static const Color amoledGray = Color(0xFF1A1A1A);
  static const Color amoledAccent = Color(0xFFFF6B6B);
  
  // Mint Green Theme Colors
  static const Color mintGreen = Color(0xFFE0F2E9);
  static const Color mintGreenAccent = Color(0xFF4ECDC4);
  static const Color mintGreenDark = Color(0xFF2D6A4F);
  
  // Lavender Theme Colors
  static const Color lavender = Color(0xFFF0E6FA);
  static const Color lavenderAccent = Color(0xFF9B59B6);
  static const Color lavenderDark = Color(0xFF6C3483);
  
  // Peach Theme Colors
  static const Color peach = Color(0xFFFFE5D9);
  static const Color peachAccent = Color(0xFFFF8C69);
  static const Color peachDark = Color(0xFFE85D4C);

  // Get colors based on color scheme
  static Color getBackgroundColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmYellow;
      case AppColorScheme.softPink:
        return softPink;
      case AppColorScheme.amoledBlack:
        return amoledBlack;
      case AppColorScheme.mintGreen:
        return mintGreen;
      case AppColorScheme.lavender:
        return lavender;
      case AppColorScheme.peach:
        return peach;
    }
  }

  static Color getAccentColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmBrown;
      case AppColorScheme.softPink:
        return softPinkAccent;
      case AppColorScheme.amoledBlack:
        return amoledAccent;
      case AppColorScheme.mintGreen:
        return mintGreenAccent;
      case AppColorScheme.lavender:
        return lavenderAccent;
      case AppColorScheme.peach:
        return peachAccent;
    }
  }

  static Color getCardColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmYellowLight;
      case AppColorScheme.softPink:
        return Colors.white;
      case AppColorScheme.amoledBlack:
        return amoledGray;
      case AppColorScheme.mintGreen:
        return Colors.white;
      case AppColorScheme.lavender:
        return Colors.white;
      case AppColorScheme.peach:
        return Colors.white;
    }
  }

  static Color getTextColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmDarkBrown;
      case AppColorScheme.softPink:
        return softPinkDark;
      case AppColorScheme.amoledBlack:
        return Colors.white;
      case AppColorScheme.mintGreen:
        return mintGreenDark;
      case AppColorScheme.lavender:
        return lavenderDark;
      case AppColorScheme.peach:
        return peachDark;
    }
  }

  static Color getSecondaryTextColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmBrown.withOpacity(0.7);
      case AppColorScheme.softPink:
        return softPinkDark.withOpacity(0.7);
      case AppColorScheme.amoledBlack:
        return Colors.white70;
      case AppColorScheme.mintGreen:
        return mintGreenDark.withOpacity(0.7);
      case AppColorScheme.lavender:
        return lavenderDark.withOpacity(0.7);
      case AppColorScheme.peach:
        return peachDark.withOpacity(0.7);
    }
  }

  static Color getNavBarColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return warmDarkBrown;
      case AppColorScheme.softPink:
        return softPinkDark;
      case AppColorScheme.amoledBlack:
        return amoledGray;
      case AppColorScheme.mintGreen:
        return mintGreenDark;
      case AppColorScheme.lavender:
        return lavenderDark;
      case AppColorScheme.peach:
        return peachDark;
    }
  }

  static bool isDarkScheme(AppColorScheme scheme) {
    return scheme == AppColorScheme.amoledBlack;
  }

  static String getSchemeName(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.warmYellow:
        return 'Warm Yellow';
      case AppColorScheme.softPink:
        return 'Soft Pink';
      case AppColorScheme.amoledBlack:
        return 'AMOLED Black';
      case AppColorScheme.mintGreen:
        return 'Mint Green';
      case AppColorScheme.lavender:
        return 'Lavender';
      case AppColorScheme.peach:
        return 'Peach';
    }
  }

  static Color getSchemePreviewColor(AppColorScheme scheme) {
    return getBackgroundColor(scheme);
  }

  // Build theme data based on color scheme
  static ThemeData getTheme(AppColorScheme scheme) {
    final bgColor = getBackgroundColor(scheme);
    final accentColor = getAccentColor(scheme);
    final cardColor = getCardColor(scheme);
    final textColor = getTextColor(scheme);
    final secondaryText = getSecondaryTextColor(scheme);
    final isDark = isDarkScheme(scheme);
    final navBarColor = getNavBarColor(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accentColor,
              secondary: accentColor,
              surface: cardColor,
              onSurface: textColor,
            )
          : ColorScheme.light(
              primary: accentColor,
              secondary: accentColor,
              surface: cardColor,
              onSurface: textColor,
            ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryText),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        indicatorColor: accentColor.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.white);
          }
          return TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.white70);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: isDark ? Colors.white : Colors.white);
          }
          return IconThemeData(color: isDark ? Colors.white60 : Colors.white70);
        }),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: secondaryText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: IconThemeData(color: textColor),
      dividerColor: textColor.withOpacity(0.1),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: accentColor.withOpacity(0.3),
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
      ),
    );
  }
}
