import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern app theme with beautiful fonts (similar to ViTune)
class AppTheme {
  // Modern fonts to replace the pixel font
  static const String primaryFont = 'Inter'; // Clean, modern sans-serif
  static const String headingFont = 'Montserrat'; // Bold, impactful headings
  static const String displayFont = 'Poppins'; // Rounded, friendly
  
  // Color palette
  static const Color primaryColor = Color(0xFFFF6B35); // Vibrant orange
  static const Color accentColor = Color(0xFFF7931E);
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color cardDark = Color(0xFF1A1F3A);
  
  // Light theme with modern fonts
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    textTheme: TextTheme(
      // Display styles - for large headings
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      
      // Headline styles - for section headers
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      
      // Title styles - for cards and tiles
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      
      // Body styles - for general text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.black54,
      ),
      
      // Label styles - for buttons and small labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
    ),
  );
  
  // Dark theme with modern fonts
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    textTheme: TextTheme(
      // Display styles
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      
      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.white70,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      ),
    ),
  );
}
