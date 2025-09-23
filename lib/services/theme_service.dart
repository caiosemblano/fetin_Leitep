import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _darkModeKey = 'modo_escuro';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setTheme(!_isDarkMode);
  }

  Future<void> setTheme(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = darkMode;
    await prefs.setBool(_darkModeKey, darkMode);
    notifyListeners();
  }

  ThemeData get lightTheme {
    const seedColor = Colors.green;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: seedColor,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: colorScheme.surface),
    );
  }

  ThemeData get darkTheme {
    const seedColor = Colors.green;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: seedColor,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: colorScheme.surface),
    );
  }
}
