import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final SaleRepository _saleRepo = SaleRepository();
  
  double _totalSales = 0.0;
  int _productCount = 0;
  int _supplierCount = 0;
  int _customerCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar ventas totales del día
      final todaySales = await _saleRepo.getTodaySales();
      _totalSales = todaySales.fold(0.0, (sum, sale) => sum + sale.total);
      
      // Cargar conteos
      _productCount = (await _productRepo.getAllProducts()).length;
      _customerCount = (await _customerRepo.getAllCustomers()).length;
      
      // Contar proveedores desde base de datos directamente
      final db = await DatabaseHelper.instance.database;
      final supplierResult = await db.rawQuery('SELECT COUNT(*) as count FROM proveedores');
      _supplierCount = (supplierResult.first['count'] as int?) ?? 0;
    } catch (e) {
      print('Error cargando dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard', 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tarjeta Resumen General
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.blue[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Resumen General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Icon(Icons.trending_up, color: isDark ? Colors.green[300] : Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ventas Totales
                  Row(children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ventas del Día', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_totalSales.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Productos
                  Row(children: [
                    Icon(Icons.inventory_2, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Productos en Inventario', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('${_productCount} unidades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Proveedores
                  Row(children: [
                    Icon(Icons.store, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Proveedores Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('${_supplierCount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Clientes
                  Row(children: [
                    Icon(Icons.person, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Clientes Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('${_customerCount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ])),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Botones Acceso Rápido
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
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
              ElevatedButton.icon(
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
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
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
              ElevatedButton.icon(
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
            ]),
          ],
        ),
      ),
    );
  }
}
