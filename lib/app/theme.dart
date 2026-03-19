import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF121216);
  static const Color elevated = Color(0xFF24242D);
  static const Color accent =
      Color(0xFF9E1B32); // Slightly more vibrant crimson
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFD1D1D8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        onPrimary: primaryText,
        onSurface: primaryText,
        secondary: secondaryText,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
            color: primaryText,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(
            color: primaryText,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        headlineMedium:
            GoogleFonts.outfit(color: primaryText, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: primaryText, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: secondaryText, fontSize: 14),
        labelSmall: GoogleFonts.inter(
            color: secondaryText,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
    );
  }
}
