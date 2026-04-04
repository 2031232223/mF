import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_layout.dart';
import './product_list_page.dart';
import './pos_page.dart';
import './purchase_page.dart';
import './sales_list_page.dart';
import './reports_page.dart';
import './settings_page.dart';
import './supplier_page.dart';
import './customer_page.dart';
import './waste_page.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/sale_repository.dart';

class HomePage extends StatefulWidget {
  final Function(bool)? onToggleTheme;
  const HomePage({super.key, this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();
  int _totalProducts = 0;
  int _ventasHoy = 0;
  int _alertasStock = 0;
  double _ingresos = 0.0;
  bool _loading = true;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final products = await _productRepo.getAllProducts();
      _totalProducts = products.length;
      _alertasStock = products.where((p) => p.stockActual <= p.stockMinimo).length;
      final sales = await _saleRepo.getTodaySales();
      _ventasHoy = sales.length;
      _ingresos = sales.fold(0.0, (sum, s) => sum + s.total);
    } catch (e) {
      print('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _handleThemeToggle(bool isDark) {
    setState(() => _isDark = isDark);
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return ResponsiveLayout(
      mobile: _HomeContent(
        onToggleTheme: _handleThemeToggle,
        loading: _loading,
        loadStats: _loadStats,
        totalProducts: _totalProducts,
        ventasHoy: _ventasHoy,
        alertasStock: _alertasStock,
        ingresos: _ingresos,
      ),
      desktop: _HomeDesktop(
        onToggleTheme: _handleThemeToggle,
        loading: _loading,
        loadStats: _loadStats,
        totalProducts: _totalProducts,
        ventasHoy: _ventasHoy,
        alertasStock: _alertasStock,
        ingresos: _ingresos,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Function(bool)? onToggleTheme;
  final bool loading;
  final VoidCallback loadStats;
  final int totalProducts, ventasHoy, alertasStock;
  final double ingresos;

  const _HomeContent({
    this.onToggleTheme,
    required this.loading,
    required this.loadStats,
    required this.totalProducts,
    required this.ventasHoy,
    required this.alertasStock,
    required this.ingresos,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadStats),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(onToggleTheme: onToggleTheme, isDark: isDark),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => loadStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _statCard('Productos', '$totalProducts', Icons.inventory_2, Colors.blue),
                        _statCard('Ventas Hoy', '$ventasHoy', Icons.shopping_cart, Colors.green),
                        _statCard('Alertas Stock', '$alertasStock', Icons.warning_amber, Colors.orange),
                        _statCard('Ingresos', '\$${ingresos.toStringAsFixed(2)}', Icons.attach_money, Colors.purple),
                      ],
                    ),
              const SizedBox(height: 24),
              const Text('Módulos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _moduleCard(context, 'Inventario', Icons.inventory_2, Colors.blue, ProductListPage(onStatsChanged: loadStats)),
                  _moduleCard(context, 'Punto de Venta', Icons.point_of_sale, Colors.green, PosPage(onSaleCompleted: loadStats)),
                  _moduleCard(context, 'Compras', Icons.shopping_bag, Colors.orange, const PurchasePage()),
                  _moduleCard(context, 'Ventas', Icons.receipt_long, Colors.teal, const SalesListPage()),
                  _moduleCard(context, 'Proveedores', Icons.business, Colors.brown, const SupplierPage()),
                  _moduleCard(context, 'Clientes', Icons.people, Colors.pink, const CustomerPage()),
                  _moduleCard(context, 'Mermas', Icons.warning_amber, Colors.red, const WastePage()),
                  _moduleCard(context, 'Reportes', Icons.bar_chart, Colors.purple, const ReportsPage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(BuildContext ctx, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _HomeDesktop extends StatelessWidget {
  final Function(bool)? onToggleTheme;
  final bool loading;
  final VoidCallback loadStats;
  final int totalProducts, ventasHoy, alertasStock;
  final double ingresos;

  const _HomeDesktop({
    this.onToggleTheme,
    required this.loading,
    required this.loadStats,
    required this.totalProducts,
    required this.ventasHoy,
    required this.alertasStock,
    required this.ingresos,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 32),
            const SizedBox(width: 12),
            Text(AppConstants.appName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadStats),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(onToggleTheme: onToggleTheme, isDark: isDark),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            leading: FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage(onStatsChanged: loadStats))),
              child: const Icon(Icons.add),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('Inventario')),
              NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('Punto de Venta')),
              NavigationRailDestination(icon: Icon(Icons.shopping_bag), label: Text('Compras')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Ventas')),
              NavigationRailDestination(icon: Icon(Icons.business), label: Text('Proveedores')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Clientes')),
              NavigationRailDestination(icon: Icon(Icons.warning_amber), label: Text('Mermas')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Reportes')),
            ],
            selectedIndex: -1,
            onDestinationSelected: (index) {
              final pages = [
                ProductListPage(onStatsChanged: loadStats),
                PosPage(onSaleCompleted: loadStats),
                const PurchasePage(),
                const SalesListPage(),
                const SupplierPage(),
                const CustomerPage(),
                const WastePage(),
                const ReportsPage(),
              ];
              Navigator.push(context, MaterialPageRoute(builder: (_) => pages[index]));
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => loadStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(child: _statCardDesktop('Productos', '$totalProducts', Icons.inventory_2, Colors.blue)),
                              const SizedBox(width: 16),
                              Expanded(child: _statCardDesktop('Ventas Hoy', '$ventasHoy', Icons.shopping_cart, Colors.green)),
                              const SizedBox(width: 16),
                              Expanded(child: _statCardDesktop('Alertas Stock', '$alertasStock', Icons.warning_amber, Colors.orange)),
                              const SizedBox(width: 16),
                              Expanded(child: _statCardDesktop('Ingresos', '\$${ingresos.toStringAsFixed(2)}', Icons.attach_money, Colors.purple)),
                            ],
                          ),
                    const SizedBox(height: 32),
                    const Text('Accesos Rápidos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.2,
                      children: [
                        _moduleCardDesktop(context, 'Inventario', Icons.inventory_2, Colors.blue, ProductListPage(onStatsChanged: loadStats)),
                        _moduleCardDesktop(context, 'Punto de Venta', Icons.point_of_sale, Colors.green, PosPage(onSaleCompleted: loadStats)),
                        _moduleCardDesktop(context, 'Compras', Icons.shopping_bag, Colors.orange, const PurchasePage()),
                        _moduleCardDesktop(context, 'Ventas', Icons.receipt_long, Colors.teal, const SalesListPage()),
                        _moduleCardDesktop(context, 'Proveedores', Icons.business, Colors.brown, const SupplierPage()),
                        _moduleCardDesktop(context, 'Clientes', Icons.people, Colors.pink, const CustomerPage()),
                        _moduleCardDesktop(context, 'Mermas', Icons.warning_amber, Colors.red, const WastePage()),
                        _moduleCardDesktop(context, 'Reportes', Icons.bar_chart, Colors.purple, const ReportsPage()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCardDesktop(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _moduleCardDesktop(BuildContext ctx, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
