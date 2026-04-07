import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/sale_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
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
          bottom: const TabBar(tabs: [
            Tab(text: 'Ventas'),
            Tab(text: 'Inventario'),
            Tab(text: 'Avanzados'),
          ]),
        ),
        body: TabBarView(children: [_buildVentas(), _buildInventario(), _buildAvanzados()]),
      ),
    );
  }

  Widget _buildVentas() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Ventas del Dia', Icons.today, Colors.green, () async {
        final sales = await _saleRepo.getTodaySales();
        final total = sales.fold(0.0, (s, x) => s + x.total);
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Ventas de Hoy'),
          content: Text('Total: \$${total.toStringAsFixed(2)}\nVentas: ${sales.length}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
      const SizedBox(height: 8),
      _card('Top 10 Productos', Icons.emoji_events, Colors.orange, () async {
        final top10 = await _saleRepo.getTop10Products();
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Top 10'),
          content: SizedBox(height: 300, width: double.maxFinite,
            child: ListView.builder(itemCount: top10.length,
              itemBuilder: (_, i) => ListTile(title: Text(top10[i]['nombre']), trailing: Text('${top10[i]['total_vendido']?.toString() ?? '0'} un.')),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
    ]);
  }

  Widget _buildInventario() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Inventario Valorado', Icons.account_balance_wallet, Colors.purple, () async {
        final products = await _productRepo.getAllProducts();
        final total = products.fold(0.0, (s, p) => s + (p.precioVenta * p.stockActual));
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Inventario'),
          content: Text('Valor total: \$${total.toStringAsFixed(2)}\nProductos: ${products.length}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
      const SizedBox(height: 8),
      _card('Stock Bajo', Icons.warning_amber, Colors.red, () async {
        final products = await _productRepo.getAllProducts();
        final low = products.where((p) => p.stockActual <= p.stockMinimo).toList();
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Stock Bajo'),
          content: SizedBox(height: 200, width: double.maxFinite,
            child: ListView.builder(itemCount: low.length,
              itemBuilder: (_, i) => ListTile(title: Text(low[i].nombre), subtitle: Text('Stock: ${low[i].stockActual}')),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
    ]);
  }

  Widget _buildAvanzados() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Flujo de Caja', Icons.account_balance, Colors.blue, () async {
        final db = await DatabaseHelper.instance.database;
        final ventas = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as t FROM ventas');
        final compras = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as t FROM compras');
        final flujo = (ventas.first['t'] as num).toDouble() - (compras.first['t'] as num).toDouble();
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Flujo de Caja'),
          content: Text('Flujo Neto: \$${flujo.toStringAsFixed(2)}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
      const SizedBox(height: 8),
      _card('Margen por Producto', Icons.calculate, Colors.purple, () async {
        final products = await _productRepo.getAllProducts();
        final margins = products.where((p) => p.costo != null && p.costo! > 0).map((p) {
          final m = ((p.precioVenta - p.costo!) / p.precioVenta) * 100;
          return {'nombre': p.nombre, 'margen': m};
        }).toList();
        if (!mounted) return;
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Margenes'),
          content: SizedBox(height: 300, width: double.maxFinite,
            child: ListView.builder(itemCount: margins.length,
              itemBuilder: (_, i) => ListTile(title: Text((margins[i]['nombre'] as String?) ?? 'Sin nombre'), trailing: Text('${(margins[i]['margen'] as num?)?.toStringAsFixed(1) ?? '0.0'}%')),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
        ));
      }),
    ]);
  }

  Widget _card(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
