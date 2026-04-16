import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../pages/pos_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/inventory_adjustment_page.dart';
import '../pages/purchases_page.dart';
import '../pages/reports_page.dart';
import '../pages/config_page.dart';
import '../pages/mermas_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  // Variables globales para mantener estado limpio
  bool _isTransitioning = false;

  final List<Widget> _pages = [
    const DashboardPage(),
    const PosPage(onSaleCompleted: _onSaleCompleted),
    const InventoryAdjustmentPage(),
    const PurchasesPage(),
    const ReportsPage(),
    const MermasPage(),
    const ConfigPage(),
  ];

  // ✅ Limpieza al cambiar de pestaña
  void _onSaleCompleted() {
    setState(() {});
  }

  void _onTabChanged(int index) {
    // ✅ Resetear estado previo
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    
    if (index != _currentIndex) {
      // Forzar reset de DB entre transiciones importantes
      if (index == 1  index == 2  index == 3) {
        // Volver a Inventario/Compras/Reportes
        Future.microtask(() => DatabaseHelper.instance.reset());
      }
      
      setState(() => _currentIndex = index);
      
      // ✅ Dejar tiempo para cleanup
      Future.delayed(const Duration(milliseconds: 100), () {        if (mounted) {
          setState(() => _isTransitioning = false);
        }
      });
    } else {
      setState(() => _isTransitioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((page) {
          // Agregar disposal listener a cada página
          return WillPopScope(
            onWillPop: () async => false, // Deshabilitar back button
            child: Stack(
              children: [
                page,
                if (_isTransitioning)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.delete_sweep), label: 'Mermas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],      ),
    );
  }
}
