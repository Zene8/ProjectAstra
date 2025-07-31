// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:projectastra/theme/app_colors.dart'; // Import the new colors

class AppTheme {
  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.bgLight,
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
    // Define button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.bg,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 5,
      ),
    ),
    // Define card themes for window styling
    cardTheme: CardTheme(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    // Define input decoration for text fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: AppColors.borderMuted),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: AppColors.borderMuted),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    // Define the color scheme
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.bg,
      secondary: AppColors.secondary,
      onSecondary: AppColors.bg,
      error: AppColors.danger,
      onError: AppColors.text,
      surface: AppColors.bgLight,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.bgLight,
      onSurfaceVariant: AppColors.textMuted,
    ),
  );
}
