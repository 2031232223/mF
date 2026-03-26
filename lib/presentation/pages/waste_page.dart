import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/inventory_adjustment.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/inventory_repository.dart';

class WastePage extends StatefulWidget {
  const WastePage({super.key});
  @override
  State<WastePage> createState() => _WastePageState();
}

class _WastePageState extends State<WastePage> {
  final _productRepo = ProductRepository();
  final _inventoryRepo = InventoryRepository();
  List<Product> _products = [];
  final Map<int, int> _quantities = {};
  String _selectedReason = 'Dañado';
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadProducts(); }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    _products = await _productRepo.getAllProducts();
    setState(() => _loading = false);
  }

  void _addToWaste(Product p) {
    if (p.id == null) return;
    setState(() => _quantities[p.id!] = (_quantities[p.id!] ?? 0) + 1);
  }

  void _removeFromWaste(int productId) {
    setState(() {
      _quantities[productId] = (_quantities[productId] ?? 1) - 1;
      if (_quantities[productId]! <= 0) _quantities.remove(productId);
    });
  }

  Future<void> _registerWaste() async {
    if (_quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Seleccione productos'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _loading = true);
    try {
      for (final entry in _quantities.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        await _inventoryRepo.registerAdjustment(InventoryAdjustment(
          productoId: product.id!,
          productoNombre: product.nombre,
          type: AdjustmentType.negative,
          cantidad: entry.value,
          costoUnitario: product.costo ?? product.precioVenta * 0.7,
          motivo: _selectedReason,
          fecha: DateTime.now().toIso8601String(),
          notas: 'Merma registrada',
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mermas registradas'), backgroundColor: Colors.green));
        _quantities.clear();
        await _loadProducts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mermas'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🗑️ Motivo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            value: _selectedReason,
            items: ['Dañado', 'Vencido', 'Robo', 'Error', 'Otro'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _selectedReason = v ?? 'Dañado'),
          ),
          const SizedBox(height: 16),
          const Text('📦 Productos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._products.map((p) => Card(child: ListTile(
            title: Text(p.nombre),
            subtitle: Text('Stock: ${p.stockActual}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: _quantities[p.id!] != null ? () => _removeFromWaste(p.id!) : null),
              Text('${_quantities[p.id!] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: p.stockActual > 0 ? () => _addToWaste(p) : null),
            ]),
          ))),
          if (_quantities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total a merma:'),
              Text('${_quantities.values.fold(0, (a, b) => a + b)} unidades', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
              onPressed: _registerWaste,
              icon: const Icon(Icons.delete_forever),
              label: const Text('REGISTRAR MERMAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            )),
          ],
        ]),
      ),
    );
  }
}
