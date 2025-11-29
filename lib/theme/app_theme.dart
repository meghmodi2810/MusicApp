import 'package:flutter/material.dart';

enum AppThemeMode { defaultTheme, pixelated, lite }

class AppTheme {
  // Theme Colors
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyBlack = Color(0xFF121212);
  static const Color spotifyDarkGray = Color(0xFF181818);
  static const Color spotifyLightGray = Color(0xFF282828);
  
  // Pixel Theme Colors
  static const Color pixelGreen = Color(0xFF50C878);
  static const Color pixelBlack = Color(0xFF1A1A1A);
  static const Color pixelGray = Color(0xFF3C3C3C);
  
  // Lite Theme Colors
  static const Color liteWhite = Color(0xFFFAFAFA);
  static const Color liteGray = Color(0xFFF5F5F5);
  static const Color liteDarkGray = Color(0xFF333333);
  static const Color liteGreen = Color(0xFF1DB954);

  // Get theme based on mode
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return defaultTheme;
      case AppThemeMode.pixelated:
        return pixelatedTheme;
      case AppThemeMode.lite:
        return liteTheme;
    }
  }

  // Default Theme (Spotify-like)
  static ThemeData get defaultTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spotifyBlack,
      primaryColor: spotifyGreen,
      colorScheme: const ColorScheme.dark(
        primary: spotifyGreen,
        secondary: Color(0xFF1ed760),
        surface: spotifyDarkGray,
        onSurface: Colors.white,
        tertiary: Color(0xFF7C4DFF),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(inherit: true, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(inherit: true, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(inherit: true, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(inherit: true, fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(inherit: true, fontSize: 14, color: Colors.white70),
        labelLarge: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: spotifyBlack.withValues(alpha: 0.95),
        indicatorColor: spotifyGreen.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(inherit: true, fontSize: 12, fontWeight: FontWeight.w600, color: spotifyGreen);
          }
          return TextStyle(inherit: true, fontSize: 12, color: Colors.grey[500]);
        }),
      ),
      cardTheme: CardThemeData(
        color: spotifyDarkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spotifyGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: spotifyLightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(inherit: true, color: Colors.grey[500], fontSize: 14),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.grey[800],
    );
  }

  // Pixelated Theme (Retro/Minecraft style)
  static ThemeData get pixelatedTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pixelBlack,
      primaryColor: pixelGreen,
      fontFamily: 'Roboto', // Use Roboto as base, apply pixel font manually where needed
      colorScheme: const ColorScheme.dark(
        primary: pixelGreen,
        secondary: Color(0xFF8B4513),
        surface: pixelGray,
        onSurface: Colors.white,
        error: Color(0xFFFF4444),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(inherit: true, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(inherit: true, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(inherit: true, fontSize: 12, color: Colors.white),
        bodyMedium: TextStyle(inherit: true, fontSize: 10, color: Colors.white70),
        bodySmall: TextStyle(inherit: true, fontSize: 8, color: Colors.white54),
        labelLarge: TextStyle(inherit: true, fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pixelGray,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pixelBlack,
        indicatorColor: pixelGreen.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(inherit: true, fontSize: 10, fontWeight: FontWeight.bold, color: pixelGreen);
          }
          return TextStyle(inherit: true, fontSize: 10, color: Colors.grey[500]);
        }),
      ),
      cardTheme: CardThemeData(
        color: pixelGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.black, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pixelGreen,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(inherit: true, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pixelGray,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: pixelGreen, width: 2),
        ),
        hintStyle: TextStyle(inherit: true, fontSize: 12, color: Colors.grey[500]),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.black,
    );
  }

  // Lite Theme (Minimal, like Spotify Lite)
  static ThemeData get liteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: liteWhite,
      primaryColor: liteGreen,
      colorScheme: const ColorScheme.light(
        primary: liteGreen,
        secondary: Color(0xFF1ed760),
        surface: Colors.white,
        onSurface: liteDarkGray,
        surfaceContainerHighest: liteGray,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(inherit: true, fontSize: 28, fontWeight: FontWeight.bold, color: liteDarkGray),
        headlineMedium: TextStyle(inherit: true, fontSize: 22, fontWeight: FontWeight.bold, color: liteDarkGray),
        titleLarge: TextStyle(inherit: true, fontSize: 18, fontWeight: FontWeight.w600, color: liteDarkGray),
        bodyLarge: TextStyle(inherit: true, fontSize: 16, color: liteDarkGray),
        bodyMedium: TextStyle(inherit: true, fontSize: 14, color: Colors.black54),
        labelLarge: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.w500, color: liteDarkGray),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: liteWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: liteDarkGray),
        titleTextStyle: TextStyle(inherit: true, fontSize: 20, fontWeight: FontWeight.bold, color: liteDarkGray),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: liteGreen.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(inherit: true, fontSize: 12, fontWeight: FontWeight.w600, color: liteGreen);
          }
          return TextStyle(inherit: true, fontSize: 12, color: Colors.grey[600]);
        }),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: liteGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: liteDarkGray,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: liteGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(inherit: true, color: Colors.grey[500], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: const IconThemeData(color: liteDarkGray),
      dividerColor: Colors.grey[200],
      listTileTheme: const ListTileThemeData(
        iconColor: liteDarkGray,
        textColor: liteDarkGray,
      ),
    );
  }

  // Helper methods
  static Color getBackgroundColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return spotifyBlack;
      case AppThemeMode.pixelated:
        return pixelBlack;
      case AppThemeMode.lite:
        return liteWhite;
    }
  }

  static Color getPrimaryColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return spotifyGreen;
      case AppThemeMode.pixelated:
        return pixelGreen;
      case AppThemeMode.lite:
        return liteGreen;
    }
  }

  static Color getCardColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
        return spotifyDarkGray;
      case AppThemeMode.pixelated:
        return pixelGray;
      case AppThemeMode.lite:
        return Colors.white;
    }
  }

  static Color getTextColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultTheme:
      case AppThemeMode.pixelated:
        return Colors.white;
      case AppThemeMode.lite:
        return liteDarkGray;
    }
  }

  static bool isDarkMode(AppThemeMode mode) {
    return mode != AppThemeMode.lite;
  }
}
