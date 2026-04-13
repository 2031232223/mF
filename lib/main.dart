import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ IMPORTS ACTUALIZADOS CON NOMBRES REALES
import 'presentation/pages/pos_page.dart';
import 'presentation/pages/product_list_page.dart'; // Para Inventario
import 'presentation/pages/purchase_page.dart';     // Para Compras
import 'presentation/pages/reports_page.dart';
import 'presentation/pages/settings_page.dart';      // O config_page.dart

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
      home: const BottomNavMainPage(),
      routes: {}, // Usando IndexedStack para navegación
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

  final List<Widget> _pages = const [
    Placeholder(key: ValueKey('pos'), child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('POS: Panel de Punto de Venta', style: TextStyle(fontSize: 18))),
    ),
    Placeholder(key: ValueKey('inventory'), child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Inventario: Gestión de Productos y Stock', style: TextStyle(fontSize: 18))),
    ),
    Placeholder(key: ValueKey('purchases'), child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Compras: Registro de Entradas', style: TextStyle(fontSize: 18))),
    ),
    Placeholder(key: ValueKey('reports'), child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Reportes: Análisis y Estadísticas', style: TextStyle(fontSize: 18))),
    ),
    Placeholder(key: ValueKey('settings'), child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Configuración: Ajustes del Sistema', style: TextStyle(fontSize: 18))),
    ),
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
