import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/database/database_helper.dart';
import 'inventory_adjustments_page.dart';

class InventoryAdjustmentPage extends StatefulWidget {
  const InventoryAdjustmentPage({super.key});

  @override
  State<InventoryAdjustmentPage> createState() => _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState extends State<InventoryAdjustmentPage> {
  final _productRepo = ProductRepository();
  List<Product> _products = [];
  Product? _selectedProduct;
  String _adjustmentType = 'positivo';
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    setState(() => _isLoading = false);
  }

  Future<void> _saveAdjustment() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Selecciona un producto')),
      );
      return;
    }
    final qty = double.tryParse(_quantityCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Cantidad inválida')),
      );
      return;
    }

    int newStock = _selectedProduct!.stockActual;
    int changeQty = qty.toInt();
    String typeLabel = '';

    if (_adjustmentType == 'positivo') {
      newStock += changeQty;
      typeLabel = 'Ajuste Positivo';
    } else if (_adjustmentType == 'negativo') {
      if (changeQty > newStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ La cantidad supera el stock actual')),
        );
        return;
      }
      newStock -= changeQty;
      changeQty = -changeQty;
      typeLabel = 'Ajuste Negativo';
    } else {
      changeQty = qty.toInt() - newStock;
      newStock = qty.toInt();
      typeLabel = 'Conteo Físico';
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('ajustes_inventario', {
        'producto_id': _selectedProduct!.id,
        'producto_nombre': _selectedProduct!.nombre,
        'tipo': typeLabel,
        'cantidad': changeQty,
        'costo_unitario': _selectedProduct!.costo ?? 0.0,
        'motivo': _reasonCtrl.text.trim(),
        'fecha': DateTime.now().toIso8601String(),
      });

      await db.rawUpdate(
        'UPDATE productos SET stock_actual = ? WHERE id = ?',
        [newStock, _selectedProduct!.id],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ajuste registrado y stock actualizado')),
      );
      _quantityCtrl.clear();
      _reasonCtrl.clear();
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Inventario'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Ajustes Masivos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InventoryAdjustmentsPage()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Product>(
                    decoration: InputDecoration(
                      labelText: 'Producto *',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: _products
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.nombre} (Stock: ${p.stockActual})'),
                            ))
                        .toList(),
                    value: _selectedProduct,
                    onChanged: (v) => setState(() => _selectedProduct = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _typeButton('positivo', '⬆️ Positivo')),
                      const SizedBox(width: 8),
                      Expanded(child: _typeButton('negativo', '⬇️ Negativo')),
                      const SizedBox(width: 8),
                      Expanded(child: _typeButton('conteo', '📦 Conteo')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _adjustmentType == 'conteo'
                          ? 'Stock Real Contado'
                          : 'Cantidad',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Motivo / Observaciones',
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
                      onPressed: _saveAdjustment,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'REGISTRAR AJUSTE',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _typeButton(String value, String label) {
    final isSelected = _adjustmentType == value;
    return ElevatedButton(
      onPressed: () => setState(() => _adjustmentType = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
