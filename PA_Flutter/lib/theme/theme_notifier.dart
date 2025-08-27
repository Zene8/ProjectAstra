
import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme;
  String _currentThemeName;
  final Map<String, ThemeData> _availableThemes;

  ThemeNotifier(this._currentTheme, this._currentThemeName, this._availableThemes);

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;
  Map<String, ThemeData> get availableThemes => _availableThemes;

  void setTheme(String themeName) {
    if (_availableThemes.containsKey(themeName)) {
      _currentTheme = _availableThemes[themeName]!;
      _currentThemeName = themeName;
      notifyListeners();
    } else {
      print('Theme $themeName not found.');
    }
  }
}

