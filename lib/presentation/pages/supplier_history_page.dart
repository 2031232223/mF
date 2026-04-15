import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';

class SupplierHistoryPage extends StatefulWidget {
  final int? supplierId;
  final String? supplierName;

  const SupplierHistoryPage({
    super.key,
    this.supplierId,
    this.supplierName,
  });

  @override
  State<SupplierHistoryPage> createState() => _SupplierHistoryPageState();
}

class _SupplierHistoryPageState extends State<SupplierHistoryPage> {
  List<Map<String, dynamic>> _purchases = [];
  double _totalPurchased = 0.0;
  int _totalItems = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSupplierHistory();
  }

  Future<void> _loadSupplierHistory() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      String where = '';
      List<dynamic> args = [];
      
      if (widget.supplierId != null) {
        where = 'WHERE proveedor_id = ?';
        args.add(widget.supplierId);
      }

      final result = await db.rawQuery('''
        SELECT 
          c.id,
          c.fecha,
          c.total,
          c.moneda,
          c.tasa_cambio,
          c.notas,
          p.nombre as proveedor_nombre,
          COUNT(cd.id) as cantidad_items
        FROM compras c
        LEFT JOIN proveedores p ON c.proveedor_id = p.id
        LEFT JOIN compra_detalles cd ON c.id = cd.compra_id
        $where
        GROUP BY c.id
        ORDER BY c.fecha DESC
      ''', args);

      setState(() {
        _purchases = result;
        _totalPurchased = result.fold(0.0, (sum, r) => sum + ((r['total'] as num?)?.toDouble() ?? 0.0));
        _totalItems = result.fold(0, (sum, r) => sum + (r['cantidad_items'] as int? ?? 0));
      });
    } catch (e) {
      print('Error cargando histórico: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierName ?? 'Histórico de Proveedores'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Compras', '${_purchases.length}'),
                        _buildSummaryItem('Items', '$_totalItems'),
                        _buildSummaryItem('Total', '\$${_totalPurchased.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                
                // Lista de compras
                Expanded(
                  child: _purchases.isEmpty
                      ? const Center(child: Text('No hay compras registradas', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _purchases.length,
                          itemBuilder: (ctx, i) => _buildPurchaseCard(_purchases[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    final date = DateTime.tryParse(purchase['fecha'] as String) ?? DateTime.now();
    final total = (purchase['total'] as num?)?.toDouble() ?? 0.0;
    final items = purchase['cantidad_items'] as int? ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(Icons.shopping_cart, color: Colors.white, size: 20),
        ),
        title: Text('Compra #${purchase['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
            Text('$items items • ${(purchase['moneda'] as String?) ?? 'CUP'}'),
            if (purchase['notas'] != null && (purchase['notas'] as String).isNotEmpty)
              Text('📝 ${(purchase['notas'] as String)}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
        trailing: Text(
          '\$${total.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        onTap: () => _showPurchaseDetails(purchase['id'] as int),
      ),
    );
  }

  void _showPurchaseDetails(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;
    final details = await db.rawQuery('''
      SELECT cd.cantidad, cd.costo_unitario, cd.subtotal, p.nombre
      FROM compra_detalles cd
      LEFT JOIN productos p ON cd.producto_id = p.id
      WHERE cd.compra_id = ?
    ''', [purchaseId]);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle de Compra'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: details.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(details[i]['nombre'] as String? ?? 'Producto #${details[i]['producto_id']}'),
              subtitle: Text('${details[i]['cantidad']} x \$${details[i]['costo_unitario']}'),
              trailing: Text('\$${details[i]['subtotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
