import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final SaleRepository _saleRepo = SaleRepository();
  
  double _totalVentas = 0.0;
  int _ventasCount = 0;
  int _productosCount = 0;
  int _clientesCount = 0;
  int _proveedoresCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Ventas
      final ventasResult = await db.rawQuery('SELECT COUNT(*) as count, SUM(total) as total FROM ventas WHERE es_fiado = 0');
      if (ventasResult.isNotEmpty) {
        _ventasCount = (ventasResult.first['count'] as int?) ?? 0;
        _totalVentas = (ventasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      }
      
      // Productos
      _productosCount = (await _productRepo.getAllProducts()).length;
      
      // Clientes
      _clientesCount = (await _customerRepo.getAllCustomers()).length;
      
      // Proveedores
      final provResult = await db.rawQuery('SELECT COUNT(*) as count FROM proveedores');
      if (provResult.isNotEmpty) _proveedoresCount = (provResult.first['count'] as int?) ?? 0;
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Negocio'),
        backgroundColor: theme.primaryColor,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Indicadores Clave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildIndicatorCard('\$ Ventas Registradas', '\$_totalVentas.toStringAsFixed(2)}', Colors.green, Icons.attach_money),
                  const SizedBox(height: 12),
                  _buildIndicatorCard('📦 Productos en Stock', '$_productosCount', Colors.orange, Icons.inventory_2),
                  const SizedBox(height: 12),
                  _buildIndicatorCard('🏪 Proveedores Activos', '$_proveedoresCount', Colors.blue, Icons.store),
                  const SizedBox(height: 12),
                  _buildIndicatorCard('👤 Clientes Registrados', '$_clientesCount', Colors.purple, Icons.person),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.lightbulb, color: Colors.yellow[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Los datos se actualizan automáticamente al registrar operaciones.', style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
