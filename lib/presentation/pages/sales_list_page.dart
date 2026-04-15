import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/customer.dart';
import '../../core/models/product.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/product_repository.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  List<Map<String, dynamic>> _sales = [];
  List<Customer> _customers = [];
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
    await _loadSales();
    await _loadCustomers();
    await _loadLockSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _loadSales() async {
    final db = await DatabaseHelper.instance.database;
    
    if (_selectedRange == null) {
      _selectedRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
    }

    final sales = await db.rawQuery('''
      SELECT v.*, c.nombre as cliente_nombre
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      WHERE v.fecha >= ? AND v.fecha <= ?
      ORDER BY v.fecha DESC
    ''', [
      _selectedRange!.start.toIso8601String(),
      _selectedRange!.end.toIso8601String(),
    ]);

    setState(() => _sales = sales);
  }

  Future<void> _loadCustomers() async {
    final repo = CustomerRepository();
    _customers = await repo.getAllCustomers();
  }

  Future<void> _loadLockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockDays = prefs.getInt('lock_days') ?? 30;
    });
  }

  bool _canEdit(DateTime ventaDate) {
    final today = DateTime.now();
    final daysSinceSale = today.difference(ventaDate).inDays;
    return daysSinceSale < _lockDays;
  }

  Future<void> _deleteSale(int saleId) async {
    final canDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: const Text('¿Está seguro que desea eliminar esta venta?'),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
    await db.delete('ventas', where: 'id = ?', whereArgs: [saleId]);
    await db.delete('venta_detalles', where: 'venta_id = ?', whereArgs: [saleId]);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Venta eliminada'), backgroundColor: Colors.green));
    _loadSales();
  }

  Future<void> _viewDetails(int saleId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('SELECT * FROM ventas WHERE id = ?', [saleId]);
    if (results.isEmpty || !mounted) return;
    
    final Map<String, dynamic> sale = results.first;
    final lines = await db.rawQuery('''
      SELECT vd.*, p.nombre as producto
      FROM venta_detalles vd
      JOIN productos p ON vd.producto_id = p.id
      WHERE vd.venta_id = ?
    ''', [saleId]);

    final date = DateTime.parse(sale['fecha'] as String);
    final canEdit = _canEdit(date);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Venta #${sale['id']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Cliente:', sale['cliente_id'] != null ? sale['cliente_id'].toString() : 'General'),
              _detailRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(date)),
              _detailRow('Moneda:', sale['moneda']?.toString() ?? 'CUP'),
              const Divider(),
              const Text('📦 Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...lines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text('${line['cantidad']} x ${line['producto']}')),
                  Text('\$${(line['subtotal'] as num).toStringAsFixed(2)}'),
                ]),
              )),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${(sale['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
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
                  backgroundColor: Colors.orange,
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
                    'La venta tiene más de $_lockDays días y está bloqueada para edición',
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
    final filtered = _sales.where((sale) {
      final clienteName = (sale['cliente_nombre'] as String?)?.toLowerCase() ?? '';
      final searchLower = _searchCtrl.text.toLowerCase();
      final totalStr = (sale['total'] as num).toString();
      return clienteName.contains(searchLower) || totalStr.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas del Día'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(hintText: 'Buscar por cliente o monto...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No hay ventas en el rango seleccionado'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      final date = DateTime.parse(s['fecha'] as String);
                      final canEdit = _canEdit(date);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: canEdit ? Colors.teal : Colors.orange,
                            child: Icon(canEdit ? Icons.receipt_long : Icons.lock, color: Colors.white),
                          ),
                          title: Text('Venta #${s['id']}'),
                          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${(s['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(s['moneda']?.toString() ?? 'CUP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          onTap: () => _viewDetails(s['id'] as int),
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
