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
  // Warm Yellow Theme Colors (Default - matching the template images exactly)
  static const Color warmYellow = Color(0xFFF7E5B7);  // Main background - creamy yellow
  static const Color warmYellowLight = Color(0xFFFFF8E7);  // Card background - lighter cream
  static const Color warmOrange = Color(0xFFE85D04);  // Primary accent - vibrant orange
  static const Color warmBrown = Color(0xFF8B2500);  // Secondary accent - deep brown/red
  static const Color warmRed = Color(0xFFBF3100);  // Highlight color - burnt orange/red
  static const Color warmDarkBrown = Color(0xFF4A1C00);  // Text color - dark brown
  static const Color warmNavBar = Color(0xFF5C1A00);  // Navigation bar - maroon/burgundy
  
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
        return warmOrange;
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
        return warmNavBar;
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

  // Custom text style that works without Google Fonts for better performance
  static TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    required Color color,
    double letterSpacing = 0,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: 'Nunito', // Fallback to system font
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
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

    // Use system fonts with fallback for better performance and reliability
    final textTheme = TextTheme(
      displayLarge: _getTextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
      displayMedium: _getTextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.3),
      displaySmall: _getTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: _getTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: _getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: _getTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: _getTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: _getTextStyle(fontSize: 16, color: textColor),
      bodyMedium: _getTextStyle(fontSize: 14, color: secondaryText),
      bodySmall: _getTextStyle(fontSize: 12, color: secondaryText),
      labelLarge: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: _getTextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: _getTextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: secondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor,
      // Improve performance by reducing animation complexity
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: _getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        indicatorColor: accentColor.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);
          }
          return _getTextStyle(fontSize: 12, color: Colors.white70);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Colors.white70);
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: _getTextStyle(fontSize: 14, color: secondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: IconThemeData(color: textColor),
      dividerColor: textColor.withOpacity(0.1),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: accentColor.withOpacity(0.3),
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      // Smooth scrolling physics
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(accentColor.withOpacity(0.5)),
        radius: const Radius.circular(10),
      ),
    );
  }
}
