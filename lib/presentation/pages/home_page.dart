import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import './product_list_page.dart';
import './pos_page.dart';
import './purchase_page.dart';
import './sales_list_page.dart';
import './reports_page.dart';
import './settings_page.dart';
import './supplier_page.dart';
import './customer_page.dart';
import './inventory_adjustment_page.dart';
import './waste_page.dart';
import './bulk_price_page.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/sale_repository.dart';

class HomePage extends StatefulWidget {
  final Function()? onToggleTheme;
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

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final products = await _productRepo.getAllProducts();
      _totalProducts = products.length;
      _alertasStock = products.where((p) => p.stockActual <= p.stockMinimo).length;
      final sales = await _saleRepo.getTodaySales();
      _ventasHoy = sales.length;
      _ingresos = sales.fold(0.0, (sum, s) => sum + s.total);
    } catch (e) { print('Error: $e'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  onToggleTheme: widget.onToggleTheme,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _loading ? const Center(child: CircularProgressIndicator()) : GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
              children: [
                _statCard('Productos', '$_totalProducts', Icons.inventory_2, Colors.blue),
                _statCard('Ventas Hoy', '$_ventasHoy', Icons.shopping_cart, Colors.green),
                _statCard('Alertas Stock', '$_alertasStock', Icons.warning_amber, Colors.orange),
                _statCard('Ingresos', '\$${_ingresos.toStringAsFixed(2)}', Icons.attach_money, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Módulos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.1,
              children: [
                _moduleCard(context, 'Inventario', Icons.inventory_2, Colors.blue, const ProductListPage()),
                _moduleCard(context, 'Punto de Venta', Icons.point_of_sale, Colors.green, const PosPage()),
                _moduleCard(context, 'Compras', Icons.shopping_bag, Colors.orange, const PurchasePage()),
                _moduleCard(context, 'Ventas', Icons.receipt_long, Colors.teal, const SalesListPage()),
                _moduleCard(context, 'Proveedores', Icons.business, Colors.brown, const SupplierPage()),
                _moduleCard(context, 'Clientes', Icons.people, Colors.pink, const CustomerPage()),
                _moduleCard(context, 'Ajustes Inv.', Icons.edit, Colors.indigo, const InventoryAdjustmentPage()),
                _moduleCard(context, 'Mermas', Icons.warning_amber, Colors.red, const WastePage()),
                _moduleCard(context, 'Precios Masivo', Icons.percent, Colors.cyan, const BulkPricePage()),
                _moduleCard(context, 'Reportes', Icons.bar_chart, Colors.purple, const ReportsPage()),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(padding: const EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 32, color: color), const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _moduleCard(BuildContext ctx, String title, IconData icon, Color color, Widget page) {
    return InkWell(onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(12),
      child: Card(elevation: 4, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: color), const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      ])),
    );
  }
}
