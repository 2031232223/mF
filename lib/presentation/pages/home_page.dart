import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/theme_provider.dart';
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

// ==================== DASHBOARD WIDGET ====================
class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título Dashboard
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // Tarjeta Resumen General
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resumen General', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Icon(Icons.trending_up, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Indicador: Ventas Totales
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ventas Totales', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('\$15,250.00', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Indicador: Productos
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Productos en Inventario', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('49 unidades', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Indicador: Proveedores
                Row(
                  children: [
                    Icon(Icons.store, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Proveedores Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('1 proveedor', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Indicador: Clientes
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clientes Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('1 cliente', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Botones de Acceso Rápido
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/pos'),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('POS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/inventory'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Inventario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/purchases'),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Compras'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/reports'),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Reportes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==================== HOME PAGE ====================
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
    const PurchasePage(),
    const ReportsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ DASHBOARD EN LA PARTE SUPERIOR (RF 40 - Prioridad Alta)
              const DashboardWidget(),
              
              // Contenido principal del módulo seleccionado
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex > 0 ? _selectedIndex - 1 : 0,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex >= 0 && _selectedIndex < _pages.length ? _selectedIndex : 0,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index + 1),
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
              ListTile(leading: const Icon(Icons.help), title: const Text('Ayuda'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Ayuda')))))),
              ListTile(leading: const Icon(Icons.feedback), title: const Text('Feedback'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Feedback')))))),
            ],
          ),
        ),
      ),
    );
  }
