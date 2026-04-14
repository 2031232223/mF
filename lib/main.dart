import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// IMPORTS DE TODOS LOS MÓDULOS
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/pos_page.dart';
import 'presentation/pages/product_list_page.dart';
import 'presentation/pages/purchase_page.dart';
import 'presentation/pages/reports_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/backup_page.dart';

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
      home: const SplashPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/pos': (context) => const PosPage(),
        '/inventory': (context) => const ProductListPage(),
        '/purchases': (context) => const PurchasePage(),
        '/reports': (context) => const ReportsPage(),
        '/settings': (context) => const SettingsPage(),
        '/backup': (context) => const BackupPage(),
      },
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
    DashboardPage(),
    PosPage(),
    ProductListPage(),
    PurchasePage(),
    ReportsPage(),
    SettingsPage(),
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
          NavigationDestination(icon: Icon(Icons.dashboard), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory_2), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), selectedIcon: Icon(Icons.shopping_cart_rounded), label: 'Compras'),
          NavigationDestination(icon: Icon(Icons.bar_chart), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
