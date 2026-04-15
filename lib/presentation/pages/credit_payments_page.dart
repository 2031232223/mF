import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/customer.dart';
import '../../core/repositories/customer_repository.dart';

class CreditPaymentsPage extends StatefulWidget {
  const CreditPaymentsPage({super.key});
  @override
  State<CreditPaymentsPage> createState() => _CreditPaymentsPageState();
}

class _CreditPaymentsPageState extends State<CreditPaymentsPage> with SingleTickerProviderStateMixin {
  final _customerRepo = CustomerRepository();
  List<Map<String, dynamic>> _debts = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  // Para registrar pago
  int? _selectedDebtId;
  Customer? _selectedCustomer;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _customers = await _customerRepo.getAllCustomers();
    await _loadDebts();
    setState(() => _isLoading = false);
  }

  Future<void> _loadDebts() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT v.id, v.fecha, v.total, v.monto_pagado, v.monto_pendiente, v.notas,
             c.nombre as cliente, c.telefono
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      WHERE v.monto_pendiente > 0
      ORDER BY v.fecha ASC
    ''');
    setState(() => _debts = results);
  }

  // RF 57: Registrar pago de fiado
  Future<void> _registerPayment() async {
    if (_selectedDebtId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Selecciona una deuda')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Monto inválido')));
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final debt = _debts.firstWhere((d) => d['id'] == _selectedDebtId);
      final currentPending = (debt['monto_pendiente'] as num).toDouble();
      final currentPaid = (debt['monto_pagado'] as num).toDouble();
      
      if (amount > currentPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ El monto supera la deuda pendiente'), backgroundColor: Colors.red),
        );
        return;
      }

      final newPaid = currentPaid + amount;
      final newPending = currentPending - amount;

      await db.rawUpdate(
        'UPDATE ventas SET monto_pagado = ?, monto_pendiente = ? WHERE id = ?',
        [newPaid, newPending, _selectedDebtId],
      );

      // Registrar el pago en notas o en tabla de pagos (opcional)
      final paymentNote = '${_notesCtrl.text.trim()} - Pago: \$${amount.toStringAsFixed(2)} el ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
      final existingNotes = debt['notas'] as String? ?? '';
      await db.rawUpdate(
        'UPDATE ventas SET notas = ? WHERE id = ?',
        ['${existingNotes.isNotEmpty ? '$existingNotes | ' : ''}$paymentNote', _selectedDebtId],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pago registrado exitosamente'), backgroundColor: Colors.red),
      );
      
      _amountCtrl.clear();
      _notesCtrl.clear();
      _selectedDebtId = null;
      _loadData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Fiado'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '💰 Deudas Pendientes'), Tab(text: '💵 Registrar Pago')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildDebtsTab(), _buildPaymentTab()],
            ),
    );
  }

  // RF 58: Ver deudas pendientes
  Widget _buildDebtsTab() {
    final filtered = _debts.where((d) {
      final clientName = (d['cliente'] as String?)?.toLowerCase() ?? '';
      return clientName.contains(_searchCtrl.text.toLowerCase());
    }).toList();

    final totalPending = _debts.fold(0.0, (sum, d) => sum + (d['monto_pendiente'] as num).toDouble());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pendiente:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$${totalPending.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('✅ No hay deudas pendientes'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final d = filtered[i];
                    final pending = (d['monto_pendiente'] as num).toDouble();
                    final total = (d['total'] as num).toDouble();
                    final progress = (total - pending) / total * 100;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: pending > total * 0.5 ? Colors.red : Colors.orange,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(d['cliente'] as String? ?? 'Cliente General', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${DateFormat('dd/MM/yyyy').format(DateTime.parse(d['fecha'] as String))}'),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: Colors.red,
                                color: pending > total * 0.5 ? Colors.red : Colors.orange,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${pending.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                            Text('de \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _showDebtDetails(d),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seleccionar Deuda:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Venta Fiada',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            items: _debts.map((d) {
              return DropdownMenuItem(
                value: d['id'] as int,
                child: Text('${d['cliente'] ?? 'General'} - \$${(d['monto_pendiente'] as num).toStringAsFixed(2)} pendiente'),
              );
            }).toList(),
            value: _selectedDebtId,
            onChanged: (v) => setState(() => _selectedDebtId = v),
          ),
          if (_selectedDebtId != null) ...[
            const SizedBox(height: 16),
            _buildDebtSummary(_debts.firstWhere((d) => d['id'] == _selectedDebtId)),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto a Pagar *',
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notas / Observaciones',
              hintText: 'Ej: Pago parcial, anticipo, etc.',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _registerPayment,
              icon: const Icon(Icons.payment),
              label: const Text('REGISTRAR PAGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummary(Map<String, dynamic> debt) {
    final total = (debt['total'] as num).toDouble();
    final paid = (debt['monto_pagado'] as num).toDouble();
    final pending = (debt['monto_pendiente'] as num).toDouble();
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 Resumen de Deuda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _summaryRow('Total Venta:', '\$${total.toStringAsFixed(2)}'),
            _summaryRow('Pagado:', '\$${paid.toStringAsFixed(2)}', color: Colors.green),
            _summaryRow('Pendiente:', '\$${pending.toStringAsFixed(2)}', color: Colors.red, bold: true),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: paid / total,
                backgroundColor: Colors.red,
                color: Colors.green,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  void _showDebtDetails(Map<String, dynamic> debt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📋 Detalle de Deuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Cliente:', debt['cliente'] as String? ?? 'General'),
              _detailRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(debt['fecha'] as String))),
              _detailRow('Total Venta:', '\$${(debt['total'] as num).toStringAsFixed(2)}'),
              _detailRow('Pagado:', '\$${(debt['monto_pagado'] as num).toStringAsFixed(2)}', color: Colors.green),
              _detailRow('Pendiente:', '\$${(debt['monto_pendiente'] as num).toStringAsFixed(2)}', color: Colors.red, bold: true),
              if (debt['notas'] != null && (debt['notas'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(debt['notas'] as String, style: TextStyle(color: Colors.grey[700])),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedDebtId = debt['id'] as int);
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Registrar Pago'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          Expanded(child: Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
