import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/database/database_helper.dart';

class WastePage extends StatefulWidget {
  const WastePage({super.key});
  @override
  State<WastePage> createState() => _WastePageState();
}

class _WastePageState extends State<WastePage> with SingleTickerProviderStateMixin {
  final List<String> _motivosMermas = ['Vencimiento', 'Dañado', 'Pérdida', 'Desecho', 'Otro'];
  String _motivoSeleccionado = 'Vencimiento';
  final _productRepo = ProductRepository();
  List<Product> _products = [];
  List<Map<String, dynamic>> _wasteHistory = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Formulario
  Product? _selectedProduct;
  String _reason = 'Vencimiento'; // RF 60
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _customReasonCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _predefinedReasons = [
    'Vencimiento', // RF 60
    'Daño físico',
    'Robo/Pérdida',
    'Error de inventario',
    'Devolución de cliente',
    'Otro', // RF 61
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyCtrl.dispose();
    _customReasonCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    await _loadWasteHistory();
    setState(() => _isLoading = false);
  }

  Future<void> _loadWasteHistory() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('SELECT * FROM mermas ORDER BY fecha DESC');
    setState(() => _wasteHistory = results);
  }

  Future<void> _registerWaste() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Selecciona un producto')));
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Cantidad inválida')));
      return;
    }
    if (qty > _selectedProduct!.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ La cantidad supera el stock actual')));
      return;
    }

    String finalReason = _reason == 'Otro' ? _customReasonCtrl.text.trim() : _reason;
    if (finalReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Ingresa un motivo')));
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('mermas', {
        'producto_id': _selectedProduct!.id,
        'producto_nombre': _selectedProduct!.nombre,
        'cantidad': qty,
        'costo_unitario': _selectedProduct!.costo ?? 0.0,
        'motivo': finalReason,
        'fecha': DateTime.now().toIso8601String(),
        'notas': '',
      });

      await db.rawUpdate('UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?', [qty, _selectedProduct!.id]);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Merma registrada'), backgroundColor: Colors.red));
      _qtyCtrl.clear();
      _customReasonCtrl.clear();
      _loadData();
      _tabController.animateTo(1); // Ir a historial
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Mermas'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '➕ Registrar'), Tab(text: '📋 Historial')],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [_buildRegisterTab(), _buildHistoryTab()],
          ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Product>(
            decoration: InputDecoration(labelText: 'Producto *', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]),
            items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p.nombre} (Stock: ${p.stockActual})'))).toList(),
            value: _selectedProduct,
            onChanged: (v) => setState(() => _selectedProduct = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Cantidad a dar de baja *', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]),
          ),
          const SizedBox(height: 16),
          const Text('Motivo de la Merma:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedReasons.map((r) => ChoiceChip(
              label: Text(r),
              selected: _reason == r,
              onSelected: (sel) => setState(() => _reason = r),
            )).toList(),
          ),
          if (_reason == 'Otro') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customReasonCtrl,
              decoration: InputDecoration(labelText: 'Especifique el motivo', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _registerWaste, icon: const Icon(Icons.delete_forever), label: const Text('REGISTRAR MERMA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final filtered = _wasteHistory.where((w) => 
      (w['producto_nombre'] as String).toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
      (w['motivo'] as String).toLowerCase().contains(_searchCtrl.text.toLowerCase())
    ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(hintText: 'Buscar por producto o motivo...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No hay mermas registradas'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final w = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.red, child: const Icon(Icons.warning_amber, color: Colors.white)),
                        title: Text(w['producto_nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${w['motivo']} • ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(w['fecha']))}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('-${w['cantidad']} un.', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text('\$${(w['costo_unitario'] as num).toStringAsFixed(2)} c/u', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  // RF 61: Motivo personalizado de merma
  TextEditingController _otroMotivoCtrl = TextEditingController();
  bool _esOtroMotivo = false;
}
