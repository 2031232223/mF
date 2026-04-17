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
  int _currentIndex = 0;  // ✅ Ahora 0 = POS (Dashboard eliminado)
  
  bool _isTransitioning = false;

  // ✅ Lista de páginas SIN Dashboard (ahora 6 elementos)
  final List<Widget> _pages = [
    const PosPage(onSaleCompleted: _onSaleCompleted),      // 0: POS
    const InventoryAdjustmentPage(),                        // 1: Inventario
    const PurchasesPage(),                                  // 2: Compras
    const ReportsPage(),                                    // 3: Reportes
    const MermasPage(),                                     // 4: Mermas ✅
    const ConfigPage(),                                     // 5: Config
  ];

  void _onSaleCompleted() {
    setState(() {});
  }

  void _onTabChanged(int index) {
    if (_isTransitioning) return;
    
    setState(() => _isTransitioning = true);
    
    if (index != _currentIndex) {
      // ✅ Ajustar índices: antes era 1||2||3, ahora es 0||1||2 (POS, Inventario, Compras)
      if (index == 0 || index == 1 || index == 2) {
        Future.microtask(() => DatabaseHelper.instance.reset());
      }
      
      setState(() => _currentIndex = index);
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
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
          return WillPopScope(
            onWillPop: () async => false,
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
      
      // ✅ BottomNavigationBar SIN Dashboard (ahora 6 ítems)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          // ❌ Dashboard ELIMINADO
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'POS'),        // 0
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),  // 1
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),   // 2
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),      // 3
          BottomNavigationBarItem(icon: Icon(Icons.delete_sweep), label: 'Mermas'),     // 4 ✅
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),         // 5
        ],
      ),
    );
  }
}