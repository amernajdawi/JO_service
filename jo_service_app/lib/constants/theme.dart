import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF6C63FF); // Main purple
  static const Color secondary = Color(0xFFFF6584); // Pink accent
  static const Color accent = Color(0xFF38CFDC); // Teal accent
  static const Color success = Color(0xFF43CA79); // Green
  static const Color warning = Color(0xFFF8B546); // Yellow
  static const Color danger = Color(0xFFFF5F58); // Red
  static const Color dark = Color(0xFF202046); // Dark blue
  static const Color light = Color(0xFFF7F9FC); // Light background
  static const Color grey = Color(0xFFA7A7A7); // Grey
  static const Color greyLight = Color(0xFFEBEBEB); // Light grey
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Sizes
  static const double baseSize = 8.0;
  static const double fontSize = 14.0;
  static const double radius = 12.0;
  static const double padding = 24.0;
  static const double margin = 20.0;

  // Font sizes
  static const double largeTitleSize = 40.0;
  static const double h1Size = 30.0;
  static const double h2Size = 22.0;
  static const double h3Size = 18.0;
  static const double h4Size = 16.0;
  static const double h5Size = 14.0;
  static const double body1Size = 30.0;
  static const double body2Size = 22.0;
  static const double body3Size = 16.0;
  static const double body4Size = 14.0;
  static const double body5Size = 12.0;
  static const double smallSize = 10.0;

  // Text styles
  static const TextStyle largeTitle =
      TextStyle(fontSize: largeTitleSize, fontWeight: FontWeight.bold);
  static const TextStyle h1 =
      TextStyle(fontSize: h1Size, fontWeight: FontWeight.bold);
  static const TextStyle h2 =
      TextStyle(fontSize: h2Size, fontWeight: FontWeight.bold);
  static const TextStyle h3 =
      TextStyle(fontSize: h3Size, fontWeight: FontWeight.w600);
  static const TextStyle h4 =
      TextStyle(fontSize: h4Size, fontWeight: FontWeight.w600);
  static const TextStyle h5 =
      TextStyle(fontSize: h5Size, fontWeight: FontWeight.w600);
  static const TextStyle body1 = TextStyle(fontSize: body1Size);
  static const TextStyle body2 = TextStyle(fontSize: body2Size);
  static const TextStyle body3 = TextStyle(fontSize: body3Size);
  static const TextStyle body4 = TextStyle(fontSize: body4Size);
  static const TextStyle body5 = TextStyle(fontSize: body5Size);
  static const TextStyle small = TextStyle(fontSize: smallSize);

  // Shadows
  static BoxShadow lightShadow = BoxShadow(
    color: black.withOpacity(0.1),
    offset: const Offset(0, 2),
    blurRadius: 3.84,
    spreadRadius: 0,
  );

  static BoxShadow mediumShadow = BoxShadow(
    color: black.withOpacity(0.15),
    offset: const Offset(0, 4),
    blurRadius: 4.65,
    spreadRadius: 0,
  );

  static BoxShadow darkShadow = BoxShadow(
    color: black.withOpacity(0.2),
    offset: const Offset(0, 6),
    blurRadius: 5.45,
    spreadRadius: 0,
  );

  // Common decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [mediumShadow],
  );

  static BoxDecoration outlineDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: greyLight),
  );

  // Theme data
  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: white,
      background: light,
      error: danger,
    ),
    scaffoldBackgroundColor: light,
    fontFamily: 'Roboto', // You can change this to your preferred font
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleLarge: h4,
      titleMedium: h5,
      bodyLarge: body3,
      bodyMedium: body4,
      bodySmall: body5,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: greyLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: greyLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primary,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: dark,
      background: const Color(0xFF121212),
      error: danger,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: dark,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
