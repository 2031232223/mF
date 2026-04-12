import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/theme_provider.dart';
import '../../core/widgets/dashboard_widget.dart';  // ✅ NUEVO WIDGET
import 'pos_page.dart';
import 'product_list_page.dart';
import 'purchase_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'inventory_adjustments_page.dart';
import 'waste_page.dart';
import 'backup_page.dart';
import 'supplier_page.dart';
import 'customer_page.dart';
import 'credit_payments_page.dart';
import 'splash_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 5; // ✅ Empieza en 5 (Dashboard)

  final List<Widget> _pages = [
    const PosPage(),
    const ProductListPage(),
    const PurchasePage(),
    const ReportsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Scaffold(
        body: _selectedIndex < 5 
            ? IndexedStack(index: _selectedIndex, children: _pages)
            : const DashboardWidget(),  // ✅ Muestra Dashboard si índice es 5
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex >= 0 && _selectedIndex < _pages.length ? _selectedIndex : 5,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index == 4 ? 5 : index + 1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Inventario'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Compras'),
            NavigationDestination(icon: Icon(Icons.analytics), label: 'Reportes'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shopping_bag, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Text('Nova ADEN', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    Text('v2.0.0', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              ListTile(leading: const Icon(Icons.supervisor_account), title: const Text('Clientes'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage()))),
              ListTile(leading: const Icon(Icons.store), title: const Text('Proveedores'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierPage()))),
              ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Pagos Fiados'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditPaymentsPage()))),
              ListTile(leading: const Icon(Icons.adjust), title: const Text('Ajustes Inventario'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryAdjustmentsPage()))),
              ListTile(leading: const Icon(Icons.delete_sweep), title: const Text('Mermas'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WastePage()))),
              ListTile(leading: const Icon(Icons.cloud_upload), title: const Text('Backup'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()))),
              const Divider(),
              ListTile(leading: const Icon(Icons.help), title: const Text('Ayuda'), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.feedback), title: const Text('Feedback'), onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
