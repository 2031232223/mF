import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static ThemeProvider? _instance;

  ThemeProvider() {
    _loadTheme();
  }

  static ThemeProvider get instance {
    _instance ??= ThemeProvider();
    return _instance!;
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
    appBarTheme: AppBarTheme(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
    cardTheme: CardTheme(color: Colors.white, elevation: 2),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: Colors.blue[900], selectedItemColor: Colors.white),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
    appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
    cardTheme: CardTheme(color: const Color(0xFF1E1E1E), elevation: 2),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: const Color(0xFF1A1A2E), selectedItemColor: Colors.white),
  );
}
