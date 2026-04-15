import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/supplier.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({super.key});

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  int _lockDays = 30;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadPurchases();
    await _loadLockSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _loadPurchases() async {
    final db = await DatabaseHelper.instance.database;
    
    if (_selectedRange == null) {
      _selectedRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
    }

    final purchases = await db.rawQuery('''
      SELECT p.*, s.nombre as proveedor_nombre
      FROM compras p
      LEFT JOIN proveedores s ON p.proveedor_id = s.id
      WHERE p.fecha >= ? AND p.fecha <= ?
      ORDER BY p.fecha DESC
    ''', [
      _selectedRange!.start.toIso8601String(),
      _selectedRange!.end.toIso8601String(),
    ]);

    setState(() => _purchases = purchases);
  }

  Future<void> _loadLockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockDays = prefs.getInt('lock_days') ?? 30;
    });
  }

  bool _canEdit(DateTime compraDate) {
    final today = DateTime.now();
    final daysSincePurchase = today.difference(compraDate).inDays;
    return daysSincePurchase < _lockDays;
  }

  Future<void> _deletePurchase(int purchaseId) async {
    final canDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Compra'),
        content: const Text('¿Está seguro que desea eliminar esta compra?'),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
      ),
    );

    if (canDelete != true) return;

    final db = await DatabaseHelper.instance.database;
    await db.delete('compras', where: 'id = ?', whereArgs: [purchaseId]);
    await db.delete('compra_detalles', where: 'compra_id = ?', whereArgs: [purchaseId]);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Compra eliminada')));
    _loadPurchases();
  }

  Future<void> _viewDetails(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('SELECT * FROM compras WHERE id = ?', [purchaseId]);
    if (results.isEmpty || !mounted) return;
    
    final Map<String, dynamic> purchase = results.first;
    final details = await db.rawQuery('''
      SELECT pd.*, pr.nombre as producto
      FROM compra_detalles pd
      JOIN productos pr ON pd.producto_id = pr.id
      WHERE pd.compra_id = ?
    ''', [purchaseId]);

    final date = DateTime.parse(purchase['fecha'] as String);
    final canEdit = _canEdit(date);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Compra #${purchase['id']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Proveedor:', purchase['proveedor_id'] != null ? purchase['proveedor_id'].toString() : 'Compra Rápida'),
              _detailRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(date)),
              const Divider(),
              const Text('📦 Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text('${d['cantidad']} x ${d['producto']}')),
                  Text('\$${(d['subtotal'] as num).toStringAsFixed(2)}'),
                ]),
              )),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${(purchase['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ]),
            ],
          ),
        ),
        actions: [
          if (canEdit) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('⚠️ Edición no disponible aún'),
                  backgroundColor: Colors.black,
                ));
              },
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Editar'),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Row(children: [
                  const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'La compra tiene más de $_lockDays días y está bloqueada para edición',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
          ],
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[700]))),
        Expanded(child: Text(value)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _purchases.where((purchase) {
      final provName = (purchase['proveedor_nombre'] as String?)?.toLowerCase() ?? '';
      final searchLower = _searchCtrl.text.toLowerCase();
      final totalStr = (purchase['total'] as num).toString();
      return provName.contains(searchLower) || totalStr.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPurchases),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(hintText: 'Buscar por proveedor o monto...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No hay compras en el rango seleccionado'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final date = DateTime.parse(p['fecha'] as String);
                      final canEdit = _canEdit(date);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: canEdit ? Colors.blue : Colors.orange,
                            child: Icon(canEdit ? Icons.receipt_long : Icons.lock, color: Colors.white),
                          ),
                          title: Text('Compra #${p['id']}'),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${(p['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(p['proveedor_nombre'] != null ? 'Proveedor' : 'Rápida', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          onTap: () => _viewDetails(p['id'] as int),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
