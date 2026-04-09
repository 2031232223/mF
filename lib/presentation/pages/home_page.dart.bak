import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/theme_provider.dart';
import 'pos_page.dart';
import 'product_list_page.dart';
import 'sales_list_page.dart';
import 'purchase_list_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'inventory_adjustments_page.dart';
import 'waste_page.dart';
import 'backup_page.dart';
import 'supplier_page.dart';
import 'customer_page.dart';
import 'credit_payments_page.dart';
import 'splash_page.dart'; // Página de bienvenida

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const PosPage(),
    const ProductListPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Scaffold(
        body: _selectedIndex == -1 ? const SplashPage() : _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex >= 0 ? _selectedIndex : 0,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Productos'),
            NavigationDestination(icon: Icon(Icons.analytics), label: 'Reportes'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Nova ADEN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('- Administrador de Negocios', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('v1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Inicio / Dashboard'),
                onTap: () { Navigator.pop(context); setState(() => _selectedIndex = -1); }, // Ir a Splash/Dashboard
              ),
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: const Text('Punto de Venta'),
                onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 0); },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Productos'),
                onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 1); },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Compras'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Ventas'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesListPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Reportes'),
                onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 2); },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Ajustes Inventario'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryAdjustmentsPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Mermas'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WastePage())); },
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Proveedores'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Clientes'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Fiado / Créditos'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditPaymentsPage())); },
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Respaldos'),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())); },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 3); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
