import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ IMPORTS DE TODAS LAS PÁGINAS REALES
import 'presentation/pages/pos_page.dart';
import 'presentation/pages/product_list_page.dart'; // Usada como Inventario
import 'presentation/pages/purchase_page.dart';     // Usada como Compras
import 'presentation/pages/reports_page.dart';
import 'presentation/pages/settings_page.dart';      // O config_page.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const BottomNavMainPage(),
      routes: {}, // Todo se maneja por IndexedStack
    );
  }
}

class BottomNavMainPage extends StatefulWidget {
  const BottomNavMainPage({super.key});

  @override
  State<BottomNavMainPage> createState() => _BottomNavMainPageState();
}

class _BottomNavMainPageState extends State<BottomNavMainPage> {
  int _currentIndex = 0;

  // ✅ AQUÍ ESTÁN LAS PÁGINAS REALES EN LUGAR DE PLACEHOLDERS
  final List<Widget> _pages = const [
    PosPage(),                     // Tabla 0: Panel Punto de Venta
    ProductListPage(),             // Tabla 1: Gestión Inventario/Productos
    PurchasePage(),                // Tabla 2: Registro Compras/Entradas
    ReportsPage(),                 // Tabla 3: Análisis Estadísticas
    SettingsPage(),                // Tabla 4: Ajustes del Sistema
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) { setState(() => _currentIndex = index); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory_2), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), selectedIcon: Icon(Icons.shopping_cart_rounded), label: 'Purchases'),
          NavigationDestination(icon: Icon(Icons.bar_chart), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
