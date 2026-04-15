import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/inventory_adjustment.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/inventory_repository.dart';

class InventoryAdjustmentPage extends StatefulWidget {
  const InventoryAdjustmentPage({super.key});
  @override
  State<InventoryAdjustmentPage> createState() => _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState extends State<InventoryAdjustmentPage> {
  final _productRepo = ProductRepository();
  final _inventoryRepo = InventoryRepository();
  List<Product> _products = [];
  Product? _selectedProduct;
  AdjustmentType _type = AdjustmentType.positive;
  int _quantity = 1;
  String _reason = '';
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadProducts(); }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    _products = await _productRepo.getAllProducts();
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_selectedProduct == null || _quantity <= 0 || _reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Complete todos los campos'), backgroundColor: Colors.black));
      return;
    }
    setState(() => _loading = true);
    try {
      await _inventoryRepo.registerAdjustment(InventoryAdjustment(
        productoId: _selectedProduct!.id!,
        productoNombre: _selectedProduct!.nombre,
        type: _type,
        cantidad: _quantity,
        costoUnitario: _selectedProduct!.costo ?? _selectedProduct!.precioVenta * 0.7,
        motivo: _reason,
        fecha: DateTime.now().toIso8601String(),
        notas: _notesController.text,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Ajuste ${_type == AdjustmentType.positive ? 'positivo' : 'negativo'} registrado'),
          backgroundColor: Colors.black,
        ));
        _quantity = 1; _reason = ''; _notesController.clear();
        await _loadProducts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.black));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de Inventario'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📦 Producto', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Product>(
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Seleccionar producto'),
            items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p.nombre} (Stock: ${p.stockActual})'))).toList(),
            value: _selectedProduct,
            onChanged: (v) => setState(() => _selectedProduct = v),
          ),
          const SizedBox(height: 16),
          const Text('🔄 Tipo de Ajuste', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [_type == AdjustmentType.positive, _type == AdjustmentType.negative],
            onPressed: (i) => setState(() => _type = i == 0 ? AdjustmentType.positive : AdjustmentType.negative),
            children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('➕ Positivo')), Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('➖ Negativo'))],
          ),
          const SizedBox(height: 16),
          const Text('🔢 Cantidad', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
            Container(width: 60, alignment: Alignment.center, child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
          ]),
          const SizedBox(height: 16),
          const Text('📝 Motivo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Seleccionar motivo'),
            items: ['Reposición', 'Error de conteo', 'Producto dañado', 'Devolución', 'Otro'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            value: _reason.isEmpty ? null : _reason,
            onChanged: (v) => setState(() => _reason = v ?? ''),
          ),
          const SizedBox(height: 16),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notas adicionales (opcional)', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 24),
          if (_selectedProduct != null)
            Card(
              child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Valor del ajuste:', style: TextStyle(fontSize: 16)),
                Text('\$${((_selectedProduct?.costo ?? _selectedProduct!.precioVenta * 0.7) * _quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ])),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
            onPressed: _loading || _selectedProduct == null ? null : _submit,
            icon: const Icon(Icons.check_circle),
            label: Text(_type == AdjustmentType.positive ? 'REGISTRAR AJUSTE +' : 'REGISTRAR AJUSTE -', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: _type == AdjustmentType.positive ? Colors.green : Colors.orange, foregroundColor: Colors.white),
          )),
        ]),
      ),
    );
  }
}
