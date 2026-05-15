import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryAmber = Color(0xFFFFA726);
  static const Color primaryOrange = Color(0xFFFF7043);
  static const Color calmBlue = Color(0xFF42A5F5);
  static const Color calmTeal = Color(0xFF26A69A);
  static const Color reflectionBlue = Color(0xFF5C6BC0);
  static const Color moodGreat = Color(0xFF66BB6A);
  static const Color moodGood = Color(0xFF9CCC65);
  static const Color moodOkay = Color(0xFFFFCA28);
  static const Color moodLow = Color(0xFFFFA726);
  static const Color moodRough = Color(0xFFEF5350);

  // Milestone colors
  static const Color bronzeMilestone = Color(0xFFCD7F32);
  static const Color silverMilestone = Color(0xFFC0C0C0);
  static const Color goldMilestone = Color(0xFFFFD700);

  static final ThemeData lightTheme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryAmber,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  static final ThemeData darkTheme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryAmber,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}