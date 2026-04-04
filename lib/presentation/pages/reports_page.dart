import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/sale_repository.dart';
import '../../core/models/product.dart';
import 'package:sqflite/sqflite.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();

  bool _loadingMovements = false;
  List<Map<String, dynamic>> _currentMovements = [];
  Product? _selectedProductForMovements;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportOptions(),
              tooltip: 'Exportar',
            ),
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
            _buildSalesTab(),
            _buildInventoryTab(),
            _buildAdvancedTab(),
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
              subtitle: 'Exportar todos los productos a CSV',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportProductsCsv();
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.receipt_long,
              title: 'Ventas del Día',
              subtitle: 'Exportar ventas de hoy a CSV',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportSalesCsv();
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.assessment,
              title: 'Top 10 Productos',
              subtitle: 'Exportar productos más vendidos',
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

  Widget _exportOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
      final csvContent = 'ID,Nombre,Código,Costo,Precio Venta,Stock,Categoría\n' +
          products.map((p) => '${p.id},"${p.nombre}","${p.codigo}",${p.costo},${p.precioVenta},${p.stockActual},"${p.categoria ?? ''}"').join('\n');
      
      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/productos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Exportado: productos.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportSalesCsv() async {
    try {
      final sales = await _saleRepo.getTodaySales();
      final csvContent = 'ID,Fecha,Total,Cliente,Monto Pagado,Monto Pendiente\n' +
          sales.map((s) => '${s.id},${s.fecha},${s.total},"${s.clienteId ?? 'General'}",${s.montoPagado},${s.montoPendiente}').join('\n');
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/ventas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Exportado: ventas_hoy.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportTop10Csv() async {
    try {
      final top10 = await _saleRepo.getTop10Products();
      final csvContent = 'Producto,ID,Total Vendido\n' +
          top10.map((p) => '"${p['nombre']}",${p['id']},${p['total_vendido']}').join('\n');
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/top10_productos_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Exportado: top10_productos.csv'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _reportCard(
            '💰 Ventas del Día',
            'Resumen de ventas hoy',
            Icons.today,
            Colors.green,
            () async {
              final sales = await _saleRepo.getTodaySales();
              final total = sales.fold(0.0, (sum, s) => sum + s.total);
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('📊 Ventas de Hoy'),
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
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _reportCard(
            '📅 Ventas por Rango',
            'Filtrar por fechas',
            Icons.date_range,
            Colors.blue,
            () async {
              final dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                ),
              );
              if (dateRange == null || !mounted) return;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('📅 Rango: ${DateFormat('dd/MM').format(dateRange.start)} - ${DateFormat('dd/MM').format(dateRange.end)}')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _reportCard(
            '🏆 Top 10 Productos',
            'Productos más vendidos',
            Icons.emoji_events,
            Colors.orange,
            () async => _showTop10Products(),
          ),
        ],
      ),
    );
  }

  Future<void> _showTop10Products() async {
    try {
      final top10 = await _saleRepo.getTop10Products();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🏆 Top 10 Productos Más Vendidos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: top10.isEmpty
                ? const Center(child: Text('Sin ventas registradas'))
                : ListView.builder(
                    itemCount: top10.length,
                    itemBuilder: (ctx, i) {
                      final product = top10[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: i < 3 ? Colors.amber : Colors.blue,
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(product['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${product['total_vendido']} unidades vendidas'),
                        trailing: Icon(Icons.trending_up, color: i < 3 ? Colors.amber : Colors.blue),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _exportTop10Csv();
              },
              icon: const Icon(Icons.download),
              label: const Text('Exportar CSV'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _reportCard(
            '📋 Inventario Valorado',
            'Valor total del stock',
            Icons.account_balance_wallet,
            Colors.purple,
            () async {
              final products = await _productRepo.getAllProducts();
              final totalValue = products.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stockActual));
              final totalCost = products.fold(0.0, (sum, p) => sum + ((p.costo ?? 0) * p.stockActual));
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('💰 Inventario Valorado'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📦 Productos: ${products.length}'),
                      Text('🏷️ Valor venta: \$${totalValue.toStringAsFixed(2)}'),
                      Text('💵 Costo total: \$${totalCost.toStringAsFixed(2)}'),
                      Text('📈 Ganancia potencial: \$${(totalValue - totalCost).toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _reportCard(
            '📊 Movimientos por Producto',
            'Historial de entradas/salidas',
            Icons.swap_horiz,
            Colors.teal,
            () async => _showProductMovementsDialog(),
          ),
          const SizedBox(height: 12),
          _reportCard(
            '⚠️ Productos con Stock Bajo',
            'Alertas de inventario',
            Icons.warning_amber,
            Colors.red,
            () async {
              final products = await _productRepo.getAllProducts();
              final lowStock = products.where((p) => p.stockActual <= p.stockMinimo).toList();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('⚠️ Stock Bajo'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: lowStock.isEmpty
                        ? const Center(child: Text('✅ Todo el inventario está bien'))
                        : ListView.builder(
                            itemCount: lowStock.length,
                            itemBuilder: (ctx, i) {
                              final p = lowStock[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.stockActual == 0 ? Colors.red : Colors.orange,
                                  child: Text('${p.stockActual}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(p.nombre),
                                subtitle: Text('Mínimo: ${p.stockMinimo}'),
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _reportCard(
            '📈 Ganancias y Márgenes',
            'Análisis de rentabilidad',
            Icons.trending_up,
            Colors.green,
            () async {
              final report = await _saleRepo.getProfitReport();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('📊 Rentabilidad'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💵 Ingresos: \$${report['ingresos'].toStringAsFixed(2)}'),
                      Text('💰 Costos: \$${report['costos'].toStringAsFixed(2)}'),
                      Text('📈 Ganancia: \$${report['ganancia'].toStringAsFixed(2)}'),
                      Text('📊 Margen: ${report['margen'].toStringAsFixed(1)}%'),
                      Text('🧾 Total ventas: ${report['ventas']}'),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _reportCard(
            '🔄 Exportar Reportes',
            'Descargar en CSV',
            Icons.download,
            Colors.blue,
            () => _showExportOptions(),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 24, child: Icon(icon, color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProductMovementsDialog() async {
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

    setState(() {
      _selectedProductForMovements = selected;
      _loadingMovements = true;
      _currentMovements = [];
    });

    await _loadProductMovements(selected.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '📦 ${selected.nombre}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingMovements
                  ? const Center(child: CircularProgressIndicator())
                  : _currentMovements.isEmpty
                      ? const Center(child: Text('Sin movimientos registrados', style: TextStyle(color: Colors.grey, fontSize: 16)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _currentMovements.length,
                          itemBuilder: (ctx, i) {
                            final m = _currentMovements[i];
                            final isEntrada = m['tipo'] == 'compra' || m['tipo'] == 'ajuste';
                            final color = isEntrada ? Colors.green : Colors.red;
                            final signo = isEntrada ? '+' : '-';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color,
                                  child: Icon(_getMovementIcon(m['tipo']), color: Colors.white, size: 20),
                                ),
                                title: Text(
                                  '${(m['tipo'] as String?)?.toUpperCase() ?? 'MOVIMIENTO'}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                ),
                                subtitle: Text(
                                  '${m['fecha']?.toString().split('T')[0] ?? 'Fecha desconocida'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$signo${m['cantidad']} un.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                                    ),
                                    Text(
                                      '\$${((m['precio'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} c/u',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadProductMovements(int productId) async {
    if (!mounted) return;

    try {
      final db = await DatabaseHelper.instance.database;

      final movements = await db.rawQuery('''
        SELECT 'compra' as tipo, c.fecha, cd.cantidad, cd.costo_unitario as precio, p.nombre as producto
        FROM compra_detalles cd
        JOIN compras c ON cd.compra_id = c.id
        JOIN productos p ON cd.producto_id = p.id
        WHERE cd.producto_id = ?
        
        UNION ALL
        
        SELECT 'venta' as tipo, v.fecha, vd.cantidad, vd.precio_unitario as precio, p.nombre as producto
        FROM venta_detalles vd
        JOIN ventas v ON vd.venta_id = v.id
        JOIN productos p ON vd.producto_id = p.id
        WHERE vd.producto_id = ?
        
        UNION ALL
        
        SELECT tipo, fecha, cantidad, costo_unitario as precio, producto_nombre as producto
        FROM ajustes_inventario
        WHERE producto_id = ?
        
        UNION ALL
        
        SELECT 'merma' as tipo, fecha, cantidad, costo_unitario as precio, producto_nombre as producto
        FROM mermas
        WHERE producto_id = ?
        
        ORDER BY fecha DESC
      ''', [productId, productId, productId, productId]);

      if (mounted) {
        setState(() {
          _currentMovements = movements;
          _loadingMovements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMovements = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  IconData _getMovementIcon(String? tipo) {
    switch (tipo) {
      case 'compra':
        return Icons.shopping_bag;
      case 'venta':
        return Icons.receipt_long;
      case 'ajuste':
        return Icons.edit;
      case 'merma':
        return Icons.warning_amber;
      default:
        return Icons.swap_horiz;
    }
  }
}
