// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Cores Principais
  static const Color primaryDark = Color(0xFF0F172A); // Slate Escuro
  static const Color accentOrange = Color(0xFFFF6500); // Laranja Corporativo
  static const Color backgroundLight = Color(0xFFF8FAFC); // Fundo Suave
  static const Color cardWhite = Colors.white;

  // Cores de Status Operacional
  static const Color statusGreen = Color(0xFF10B981);
  static const Color statusOrange = Color(0xFFF59E0B);
  static const Color statusGrey = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        primary: primaryDark,
        secondary: accentOrange,
        surface: cardWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: cardWhite,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}