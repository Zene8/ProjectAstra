import 'package:flutter/material.dart';
import 'package:projectastra/theme/theme_parser.dart';

class AppTheme {
  static ThemeData fromParsedTheme(ParsedTheme parsedTheme) {
    return ThemeData(
      brightness: parsedTheme.name.toLowerCase().contains('dark')
          ? Brightness.dark
          : Brightness.light,
      primaryColor: parsedTheme.colors['Primary'],
      colorScheme: ColorScheme(
        primary: parsedTheme.colors['Primary']!,
        onPrimary: parsedTheme.colors['OnPrimary']!,
        secondary: parsedTheme.colors['Secondary']!,
        onSecondary: parsedTheme.colors['OnSecondary']!,
        error: parsedTheme.colors['Error']!,
        onError: parsedTheme.colors['OnError']!,
        surface: parsedTheme.colors['Surface']!,
        onSurface: parsedTheme.colors['OnSurface']!,
        brightness: parsedTheme.name.toLowerCase().contains('dark')
            ? Brightness.dark
            : Brightness.light,
      ),
      scaffoldBackgroundColor: parsedTheme.colors['Background'],
      appBarTheme: AppBarTheme(
        backgroundColor: parsedTheme.colors['Surface'],
        foregroundColor: parsedTheme.colors['OnSurface'],
        elevation: 4,
      ),
      // FIX: Use CardThemeData instead of CardTheme for older Flutter versions.
      cardTheme: CardThemeData(
        color: parsedTheme.colors['Surface'],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: parsedTheme.colors['Primary'],
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: parsedTheme.colors['Primary'],
          foregroundColor: parsedTheme.colors['OnPrimary'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: parsedTheme.colors['Secondary'],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parsedTheme.colors['Surface'],
        labelStyle: TextStyle(color: parsedTheme.colors['OnSurface']),
        hintStyle:
            TextStyle(color: parsedTheme.colors['OnSurface']!.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: parsedTheme.typography['FontFamily'],
          fontSize: double.tryParse(parsedTheme.typography['Heading1']
                  ?.split(',')[0]
                  .replaceAll('px', '')
                  .trim() ??
              '32'),
          fontWeight: FontWeight.bold,
          color: parsedTheme.colors['OnBackground'],
        ),
        titleMedium: TextStyle(
          fontFamily: parsedTheme.typography['FontFamily'],
          fontSize: double.tryParse(parsedTheme.typography['BodyText']
                  ?.split(',')[0]
                  .replaceAll('px', '')
                  .trim() ??
              '16'),
          fontWeight: FontWeight.normal,
          color: parsedTheme.colors['OnBackground'],
        ),
        bodyMedium: TextStyle(
          fontFamily: parsedTheme.typography['FontFamily'],
          fontSize: double.tryParse(parsedTheme.typography['BodyText']
                  ?.split(',')[0]
                  .replaceAll('px', '')
                  .trim() ??
              '16'),
          color: parsedTheme.colors['OnBackground'],
        ),
        bodySmall: TextStyle(
          fontFamily: parsedTheme.typography['FontFamily'],
          fontSize: double.tryParse(parsedTheme.typography['SmallText']
                  ?.split(',')[0]
                  .replaceAll('px', '')
                  .trim() ??
              '12'),
          color: parsedTheme.colors['OnBackground'],
        ),
      ),
    );
  }
}
