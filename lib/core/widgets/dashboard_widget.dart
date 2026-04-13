import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';
import '../../core/repositories/config_repository.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final todaySales = await _saleRepo.getTodaySales();
      _totalSales = todaySales.fold(0.0, (sum, s) => sum + s.total);
      
      _productCount = (await _productRepo.getAllProducts()).length;
      _customerCount = (await _customerRepo.getAllCustomers()).length;
      
      final db = await DatabaseHelper.instance.database;
      final supplierResult = await db.rawQuery('SELECT COUNT(*) as count FROM proveedores');
      _supplierCount = (supplierResult.first['count'] as int?) ?? 0;
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
            Text('Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.blue[200]!),
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
                  
                  _buildMetricRow(Icons.attach_money, Colors.green, 'Ventas del Día', '\$${_totalSales.toStringAsFixed(2)}'),
                  _buildDivider(isDark),
                  _buildMetricRow(Icons.inventory_2, Colors.orange, 'Productos en Inventario', '${_productCount} unidades'),
                  _buildDivider(isDark),
                  _buildMetricRow(Icons.store, Colors.blue, 'Proveedores Registrados', '${_supplierCount}'),
                  _buildDivider(isDark),
                  _buildMetricRow(Icons.person, Colors.purple, 'Clientes Registrados', '${_customerCount}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ SECCIÓN NOTAS DIARIAS (RF 70)
            FutureBuilder<String?>(
              future: ConfigRepository().obtenerNotaDiaria(),
              builder: (context, snapshot) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.note_add, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text('Notas Diarias (RF 70)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        const Divider(height: 24),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Escribe tus notas para hoy...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                          ),
                          onChanged: (val) {
                            ConfigRepository().guardarNotaDiaria(val);
                          },
                          initialValue: snapshot.data ?? '',
                        ),
                        const SizedBox(height: 8),
                        Text('Última actualización: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Wrap(spacing: 8, runSpacing: 8, children: [
              _buildActionButton(context, '/pos', Icons.point_of_sale, 'POS', Colors.blue),
              _buildActionButton(context, '/inventory', Icons.inventory_2, 'Inventario', Colors.teal),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _buildActionButton(context, '/purchases', Icons.shopping_cart, 'Compras', Colors.orange),
              _buildActionButton(context, '/reports', Icons.bar_chart, 'Reportes', Colors.red),
            ]),
            
            if (_isLoading) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, Color color, String title, String value) {
    return Row(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ])),
    ]);
  }

  Widget _buildDivider(bool isDark) => Divider(height: 24, color: isDark ? Colors.grey[700] : Colors.grey[300]);

  Widget _buildActionButton(BuildContext context, String route, IconData icon, String label, Color bgColor) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }
}
