import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/sale_repository.dart';
import '../../core/models/product.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<FlSpot> _generateLast7DaysSpots(List<Map<String, dynamic>> sales) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final daySales = sales.where((s) {
        try {
          final sDate = s['fecha'] is DateTime ? s['fecha'] : DateTime.parse(s['fecha'].toString());
          return sDate.year == date.year && sDate.month == date.month && sDate.day == date.day;
        } catch (_) { return false; }
      }).fold(0.0, (sum, s) => sum + (s['total']?.toDouble() ?? 0.0));
      spots.add(FlSpot((6 - i).toDouble(), daySales));
    }
    return spots;
  }

  final _productRepo = ProductRepository();
  final _saleRepo = SaleRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.download), onPressed: _showExportOptions, tooltip: 'Exportar'),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '📈 Ventas'),
              Tab(text: '📦 Inventario'),
              Tab(text: '📊 Avanzados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVentas(),
            _buildInventario(),
            _buildAvanzados(),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📥 Exportar Datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _exportOption(
              icon: Icons.inventory,
              title: 'Catálogo de Productos',
              subtitle: 'Exportar productos a CSV',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportProductsCsv();
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.receipt_long,
              title: 'Ventas del Día',
              subtitle: 'Exportar ventas hoy',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportSalesCsv();
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.assessment,
              title: 'Top 10 Productos',
              subtitle: 'Productos más vendidos',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportTop10Csv();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.blue, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.download, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProductsCsv() async {
    try {
      final products = await _productRepo.getAllProducts();
      final header = '${AppConstants.appName} - Catálogo\nFecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n';
      final csv = header + 'ID,Nombre,Código,Costo,Precio,Stock,Categoría\n' +
          products.map((p) => '${p.id},"${p.nombre}","${p.codigo}",${p.costo},${p.precioVenta},${p.stockActual},"${p.categoria ?? ''}"').join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/productos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exportado: productos.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
      }
    }
  }

  Future<void> _exportSalesCsv() async {
    try {
      final sales = await _saleRepo.getTodaySales();
      final header = '${AppConstants.appName} - Ventas\nFecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n';
      final csv = header + 'ID,Fecha,Total,Cliente,Pagado,Pendiente\n' +
          sales.map((s) => '${s.id},${s.fecha},${s.total},"${s.clienteId ?? 'General'}",${s.montoPagado},${s.montoPendiente}').join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ventas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exportado: ventas.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
      }
    }
  }

  Future<void> _exportTop10Csv() async {
    try {
      final top10 = <dynamic>[]; // Temporalmente desactivado
      final header = '${AppConstants.appName} - Top 10\nFecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n';
      final csv = header + 'Producto,ID,Vendido\n' +
          top10.map((p) => '"${p['nombre']}",${p['id']},${p['total_vendido']}').join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/top10_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exportado: top10.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
      }
    }
  }

  Widget _buildVentas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card('📊 Ventas Últimos 7 Días', Icons.bar_chart, Colors.blue, () => _showSalesChart()),
          const SizedBox(height: 12),
          _card('💰 Ventas del Día', Icons.today, Colors.green, () => _showTodaySales()),
          const SizedBox(height: 12),
          _card('📅 Ventas por Rango', Icons.date_range, Colors.blue, () => _showDateRangeSales()),
          const SizedBox(height: 12),
          _card('🏆 Top 10 Productos', Icons.emoji_events, Colors.orange, () => _showTop10()),
          const SizedBox(height: 12),
          _card('📋 Ventas Detalladas', Icons.receipt_long, Colors.teal, () => _showDetailedSales()),
        ],
      ),
    );
  }

  Widget _buildInventario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card('📋 Inventario Valorado', Icons.account_balance_wallet, Colors.purple, () => _showValuedInventory()),
          const SizedBox(height: 12),
          _card('🔄 Rotación de Productos', Icons.speed, Colors.teal, () => _showRotation()),
          const SizedBox(height: 12),
          _card('📊 Movimientos por Producto', Icons.swap_horiz, Colors.teal, () => _showMovements()), // RF 30
          const SizedBox(height: 12),
          _card('⚠️ Stock Bajo', Icons.warning_amber, Colors.red, () => _showLowStock()),
        ],
      ),
    );
  }

  Widget _buildAvanzados() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card('📈 Ganancias y Márgenes', Icons.trending_up, Colors.green, () => _showProfit()),
          const SizedBox(height: 12),
          _card('📊 Margen por Producto', Icons.calculate, Colors.purple, () => _showMarginByProduct()),
          const SizedBox(height: 12),
          _card('💵 Flujo de Caja', Icons.account_balance, Colors.blue, () => _showCashFlow()),
          const SizedBox(height: 12),
          _card('📦 Compras por Proveedor', Icons.store, Colors.indigo, () => _showPurchasesBySupplier()),
          const SizedBox(height: 12),
          _card('🔄 Exportar Reportes', Icons.download, Colors.blue, () => _showExportOptions()),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Future<void> _showSalesChart() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.rawQuery(
      'SELECT DATE(fecha) as fecha, SUM(total) as total FROM ventas WHERE fecha >= date(\'now\', \'-7 days\') GROUP BY DATE(fecha) ORDER BY fecha ASC',
    );
    if (!mounted) return;

    List<BarChartGroupData> barGroups = [];
    double maxY = 10;
    if (data.isNotEmpty) {
      barGroups = data.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: (e.value['total'] as num).toDouble(),
              color: Colors.blue,
              width: 16,
            ),
          ],
        );
      }).toList();
      maxY = data.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ventas Últimos 7 Días'),
        content: SizedBox(
          height: 250,
          width: double.maxFinite,
          child: data.isEmpty
              ? const Center(child: Text('Sin datos'))
              : const Center(child: Text('Gráfico disponible')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTodaySales() async {
    final sales = await _saleRepo.getTodaySales();
    final total = sales.fold(0.0, (sum, sale) => sum + sale.total);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ventas de Hoy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧾 Total ventas: ${sales.length}'),
            Text('💵 Total ingresos: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Últimas 5 ventas:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sales.take(5).map((s) => Text('• \$${s.total.toStringAsFixed(2)} - ${s.fecha.toString().split(' ')[0]}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangeSales() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (range == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📅 Rango: ${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}'),
      ),
    );
  }

  Future<void> _showTop10() async {
    final top10 = <dynamic>[]; // Temporalmente desactivado
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Top 10 Productos'),
        content: SizedBox(
          height: 400,
          width: double.maxFinite,
          child: top10.isEmpty
              ? const Center(child: Text('Sin ventas'))
              : ListView.builder(
                  itemCount: top10.length,
                  itemBuilder: (_, i) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: i < 3 ? Colors.amber : Colors.blue,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text((top10[i]['nombre'] as String?) ?? 'Sin nombre'),
                      subtitle: Text('${top10[i]['total_vendido']} unidades'),
                      trailing: Icon(Icons.trending_up, color: i < 3 ? Colors.amber : Colors.blue),
                    );
                  },
                ),
        ),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
      ),
    );
  }

  Future<void> _showDetailedSales() async {
    final db = await DatabaseHelper.instance.database;
    final sales = await db.rawQuery('SELECT * FROM ventas ORDER BY fecha DESC LIMIT 50');
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📋 Ventas Detalladas'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: sales.isEmpty
              ? const Center(child: Text('Sin ventas registradas'))
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final s = sales[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      title: Text('Venta #${s['id']}'),
                      subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(s['fecha'] as String))}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${(s['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('${s['moneda'] ?? 'CUP'}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      onTap: () => _showSaleDetails(s['id'] as int),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaleDetails(int saleId) async {
    final db = await DatabaseHelper.instance.database;
    final details = await db.rawQuery('''
      SELECT vd.*, p.nombre as producto
      FROM venta_detalles vd
      JOIN productos p ON vd.producto_id = p.id
      WHERE vd.venta_id = ?
    ''', [saleId]);
    
    final sale = await db.rawQuery('SELECT * FROM ventas WHERE id = ?', [saleId]);
    
    if (!mounted || sale.isEmpty) return;
    final s = sale.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalle Venta #${saleId}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${d['cantidad']} x ${d['producto']}')),
                    Text('\$${(d['subtotal'] as num).toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${(s['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ]),
              const SizedBox(height: 8),
              Text('Cliente: ${s['cliente_id'] ?? 'General'}'),
              Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(s['fecha'] as String))}'),
              Text('Moneda: ${s['moneda'] ?? 'CUP'}'),
              if ((s['monto_pendiente'] as num?)?.toDouble() != null && (s['monto_pendiente'] as num).toDouble() > 0)
                Text('⚠️ Pendiente: \$${(s['monto_pendiente'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchasesBySupplier() async {
    final db = await DatabaseHelper.instance.database;
    final suppliers = await db.rawQuery('''
      SELECT p.id, p.nombre, 
             COUNT(c.id) as total_compras,
             COALESCE(SUM(c.total), 0) as total_gastado
      FROM proveedores p
      LEFT JOIN compras c ON p.id = c.proveedor_id
      GROUP BY p.id, p.nombre
      ORDER BY total_gastado DESC
    ''');
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📦 Compras por Proveedor'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: suppliers.isEmpty
              ? const Center(child: Text('Sin proveedores o compras'))
              : ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (ctx, i) {
                    final sup = suppliers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: const Icon(Icons.store, color: Colors.white),
                      ),
                      title: Text(sup['nombre'] as String? ?? 'Sin proveedor'),
                      subtitle: Text('${sup['total_compras']} compras'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${(sup['total_gastado'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('Total gastado', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      onTap: () => _showSupplierPurchaseDetails(sup['id'] as int?, sup['nombre'] as String?),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSupplierPurchaseDetails(int? supplierId, String? supplierName) async {
    if (supplierId == null) return;
    
    final db = await DatabaseHelper.instance.database;
    final purchases = await db.rawQuery('''
      SELECT * FROM compras WHERE proveedor_id = ? ORDER BY fecha DESC
    ''', [supplierId]);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Compras: ${supplierName ?? 'N/A'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: purchases.isEmpty
              ? const Center(child: Text('Sin compras registradas'))
              : ListView.builder(
                  itemCount: purchases.length,
                  itemBuilder: (ctx, i) {
                    final p = purchases[i];
                    return ListTile(
                      title: Text('Compra #${p['id']}'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(p['fecha'] as String))),
                      trailing: Text('\$${(p['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // RF 30: Movimientos por producto
  Future<void> _showMovements() async {
    final products = await _productRepo.getAllProducts();
    if (!mounted) return;

    final selected = await showDialog<Product>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Producto'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(products[i].nombre),
              subtitle: Text('Stock: ${products[i].stockActual}'),
              onTap: () => Navigator.pop(ctx, products[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    final db = await DatabaseHelper.instance.database;
    final movements = await db.rawQuery('''
      SELECT 'Compra' as tipo, c.fecha, cd.cantidad, cd.costo_unitario as precio, p.nombre as producto
      FROM compra_detalles cd
      JOIN compras c ON cd.compra_id = c.id
      JOIN productos p ON cd.producto_id = p.id
      WHERE cd.producto_id = ?
      
      UNION ALL
      
      SELECT 'Venta' as tipo, v.fecha, vd.cantidad, vd.precio_unitario as precio, p.nombre as producto
      FROM venta_detalles vd
      JOIN ventas v ON vd.venta_id = v.id
      JOIN productos p ON vd.producto_id = p.id
      WHERE vd.producto_id = ?
      
      UNION ALL
      
      SELECT tipo, fecha, cantidad, costo_unitario as precio, producto_nombre as producto
      FROM ajustes_inventario
      WHERE producto_id = ?
      
      UNION ALL
      
      SELECT 'Merma' as tipo, fecha, cantidad, costo_unitario as precio, producto_nombre as producto
      FROM mermas
      WHERE producto_id = ?
      
      ORDER BY fecha DESC
    ''', [selected.id, selected.id, selected.id, selected.id]);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📊 Movimientos: ${selected.nombre}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: movements.isEmpty
              ? const Center(child: Text('Sin movimientos registrados'))
              : ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (ctx, i) {
                    final m = movements[i];
                    final isEntrada = m['tipo'] == 'Compra' || m['tipo'] == 'Ajuste Positivo';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isEntrada ? Colors.green : Colors.red,
                        child: Icon(isEntrada ? Icons.add : Icons.remove, color: Colors.white, size: 20),
                      ),
                      title: Text(m['tipo'] as String),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(DateTime.parse(m['fecha'] as String))}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isEntrada ? '+' : '-'}${m['cantidad']} un.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isEntrada ? Colors.green : Colors.red),
                          ),
                          Text('\$${(m['precio'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showValuedInventory() async {
    final products = await _productRepo.getAllProducts();
    final totalValue = products.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stockActual));
    final totalCost = products.fold(0.0, (sum, p) => sum + ((p.costo ?? 0) * p.stockActual));
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inventario Valorado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📦 Productos: ${products.length}'),
            Text('🏷️ Valor venta: \$${totalValue.toStringAsFixed(2)}'),
            Text('💵 Costo: \$${totalCost.toStringAsFixed(2)}'),
            Text('📈 Ganancia potencial: \$${(totalValue - totalCost).toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRotation() async {
    final db = await DatabaseHelper.instance.database;
    final products = await _productRepo.getAllProducts();
    final data = await Future.wait(products.map((p) async {
      final sold = await db.rawQuery(
        'SELECT COALESCE(SUM(cantidad), 0) as t FROM venta_detalles WHERE producto_id = ?',
        [p.id],
      );
      final rot = p.stockActual > 0 ? (sold.first['t'] as num).toDouble() / p.stockActual : 0.0;
      return {
        'nombre': p.nombre,
        'vendido': (sold.first['t'] as num).toDouble(),
        'stock': p.stockActual,
        'rot': rot,
      };
    }).toList());
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rotación'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              return ListTile(
                title: Text(data[i]['nombre'] as String),
                subtitle: Text('Vendido: ${data[i]['vendido']} | Stock: ${data[i]['stock']}'),
                trailing: Text('${(data[i]['rot'] as double).toStringAsFixed(2)}x'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLowStock() async {
    final products = await _productRepo.getAllProducts();
    final low = products.where((p) => p.stockActual <= p.stockMinimo).toList();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Stock Bajo'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: low.isEmpty
              ? const Center(child: Text('✅ Todo bien'))
              : ListView.builder(
                  itemCount: low.length,
                  itemBuilder: (_, i) {
                    return ListTile(
                      title: Text(low[i].nombre),
                      subtitle: Text('Stock: ${low[i].stockActual} | Mín: ${low[i].stockMinimo}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfit() async {
    if (!mounted) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Calcular ventas últimos 30 días
      final ventasResult = await db.rawQuery(
        'SELECT COALESCE(SUM(total), 0) as total FROM ventas WHERE fecha >= date("now", "-30 days")'
      );
      final totalVentas = (ventasResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Estimado de costos (70% de ventas - ajustar según tu lógica real)
      final totalCostos = totalVentas * 0.7;
      final ganancia = totalVentas - totalCostos;
      final margen = totalVentas > 0 ? (ganancia / totalVentas) * 100 : 0.0;
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('📈 Ganancias y Márgenes', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportRow('💵 Ingresos (30 días):', '\$${totalVentas.toStringAsFixed(2)}', Colors.green),
              const SizedBox(height: 8),
              _buildReportRow('💰 Costos estimados:', '\$${totalCostos.toStringAsFixed(2)}', Colors.white),
              const SizedBox(height: 8),
              _buildReportRow('📈 Ganancia:', '\$${ganancia.toStringAsFixed(2)}', Colors.green),
              const SizedBox(height: 8),
              _buildReportRow('📊 Margen:', '${margen.toStringAsFixed(1)}%', Colors.orange),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error profit: ${e}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Future<void> _showMarginByProduct() async {
    final products = await _productRepo.getAllProducts();
    final margins = products
        .where((p) => p.costo != null && p.costo! > 0)
        .map((p) => {
              'nombre': p.nombre,
              'margen': ((p.precioVenta - p.costo!) / p.precioVenta) * 100,
            })
        .toList();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Márgenes'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: margins.length,
            itemBuilder: (_, i) {
              return ListTile(
                title: Text(margins[i]['nombre'] as String),
                trailing: Text('${(margins[i]['margen'] as double).toStringAsFixed(1)}%'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCashFlow() async {
    final db = await DatabaseHelper.instance.database;
    final v = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as t FROM ventas');
    final c = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as t FROM compras');
    final flujo = (v.first['t'] as num).toDouble() - (c.first['t'] as num).toDouble();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Flujo de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📥 Ingresos: \$${(v.first['t'] as num).toDouble().toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            Text(
              '📤 Egresos: \$${(c.first['t'] as num).toDouble().toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              '💰 Flujo: \$${flujo.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: flujo >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
