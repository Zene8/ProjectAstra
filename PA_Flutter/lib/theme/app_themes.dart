import 'package:flutter/material.dart';
import 'package:projectastra/theme/app_colors.dart';

class AppThemes {
  static final ThemeData darkAstra = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.accentBlue,
      surface: AppColors.darkBackground,
      error: Color(0xFFD32F2F),
      onPrimary: AppColors.lightText,
      onSecondary: AppColors.lightText,
      onSurface: AppColors.lightText,
      onError: AppColors.lightText,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    // ... other theme properties
  );

  static final ThemeData lightAstra = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.lightPurple, // Light purple
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPurple, // Light purple
      secondary: AppColors.accentBlue, // Shades of white
      surface: Colors.white, // Shades of white
      error: Color(0xFFC62828),
      onPrimary: Colors.black, // Text on primary
      onSecondary: Colors.black, // Text on background
      onSurface: Colors.black, // Text on surface
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white, // Shades of white
    // ... other theme properties
  );

  static final Map<String, ThemeData> availableThemes = {
    'Dark Astra': darkAstra,
    'Light Astra': lightAstra,
  };
}
