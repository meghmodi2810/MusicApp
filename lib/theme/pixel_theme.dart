import 'package:flutter/material.dart';

class PixelTheme {
  // Minecraft-inspired color palette
  static const Color primary = Color(0xFF50C878); // Emerald green
  static const Color secondary = Color(0xFF8B4513); // Oak brown
  static const Color accent = Color(0xFFFFD700); // Gold
  
  static const Color coalBlack = Color(0xFF1A1A1A);
  static const Color stoneGray = Color(0xFF3C3C3C);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color surfaceLight = Color(0xFF404040);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF707070);
  
  static const Color pixelBorder = Color(0xFF000000);
  static const Color danger = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFAA00);
  static const Color success = Color(0xFF50C878);
  
  // Pixel font
  static const String pixelFont = 'PressStart2P';
  
  // Text styles with pixel font
  static const TextStyle headingLarge = TextStyle(
    fontFamily: pixelFont,
    fontSize: 24,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontFamily: pixelFont,
    fontSize: 18,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontFamily: pixelFont,
    fontSize: 14,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: pixelFont,
    fontSize: 12,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: pixelFont,
    fontSize: 10,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: pixelFont,
    fontSize: 8,
    color: textMuted,
    height: 1.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontFamily: pixelFont,
    fontSize: 12,
    color: textPrimary,
    height: 1.4,
  );
  
  // Pixel-styled decorations
  static BoxDecoration pixelButton({
    Color color = primary,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: pixelBorder, width: 3),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
    );
  }
  
  static BoxDecoration pixelCard({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      border: Border.all(color: pixelBorder, width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }
  
  static BoxDecoration pixelBox({
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      border: Border.all(
        color: borderColor ?? pixelBorder,
        width: 2,
      ),
    );
  }
  
  // Theme data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: coalBlack,
      fontFamily: pixelFont,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headingMedium,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        displaySmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
    );
  }
}
