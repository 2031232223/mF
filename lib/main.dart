import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// IMPORTS COMPLETOS
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/pos_page.dart';
import 'presentation/pages/product_list_page.dart';
import 'presentation/pages/purchase_page.dart';
import 'presentation/pages/reports_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/notes_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    
    return MaterialApp(
      title: 'Nova Aden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      themeMode: ThemeMode.system,
      home: const SplashPage(), // ✅ SPLASH SCREEN COMO INICIO
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/pos': (context) => PosPage(),
        '/inventory': (context) => ProductListPage(),
        '/purchases': (context) => PurchasePage(),
        '/reports': (context) => ReportsPage(),
        '/settings': (context) => SettingsPage(),
        '/notes': (context) => NotesPage(),
      },
    );
  }
}
