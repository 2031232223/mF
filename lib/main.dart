import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/splash_page.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  runApp(NovaAdenApp(initialDarkMode: isDark));
}

class NovaAdenApp extends StatefulWidget {
  final bool initialDarkMode;
  const NovaAdenApp({super.key, required this.initialDarkMode});

  @override
  State<NovaAdenApp> createState() => _NovaAdenAppState();
}

class _NovaAdenAppState extends State<NovaAdenApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDarkMode;
  }

  void _toggleTheme(bool isDarkMode) async {
    setState(() => _isDark = isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _isDark ? _darkTheme : _lightTheme,
      home: SplashPage(onToggleTheme: _toggleTheme, isDark: _isDark),
    );
  }

  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1976D2),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF212121), fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFF212121), fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFF212121), fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF212121), fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF212121), fontSize: 18, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFF212121), fontSize: 16, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Color(0xFF212121), fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFF212121), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF212121), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF757575), fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF388E3C),
      surface: Colors.white,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF212121),
      onError: Colors.white,
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF42A5F5),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF42A5F5),
      foregroundColor: Color(0xFF212121),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: const Color(0xFF212121),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF424242))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5),
      secondary: Color(0xFF66BB6A),
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFEF5350),
      onPrimary: Color(0xFF212121),
      onSecondary: Color(0xFF212121),
      onSurface: Colors.white,
      onError: Color(0xFF212121),
    ),
  );
}
