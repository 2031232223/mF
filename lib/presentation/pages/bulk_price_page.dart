import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';

class BulkPricePage extends StatefulWidget {
  const BulkPricePage({super.key});
  @override
  State<BulkPricePage> createState() => _BulkPricePageState();
}

class _BulkPricePageState extends State<BulkPricePage> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _loading = false;
  double _percentageChange = 0;
  bool _increase = true;
  final List<int> _selectedIds = [];

  @override
  void initState() { 
    super.initState(); 
    _loadProducts(); 
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    _products = await _repo.getAllProducts();
    setState(() => _loading = false);
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) { 
        _selectedIds.remove(id); 
      } else { 
        _selectedIds.add(id); 
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _products.length) { 
        _selectedIds.clear(); 
      } else { 
        _selectedIds.addAll(_products.map((p) => p.id!)); 
      }
    });
  }

  Future<void> _applyChanges() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Seleccione productos'), backgroundColor: Colors.black),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      for (final id in _selectedIds) {
        final product = _products.firstWhere((p) => p.id == id);
        final newPrice = _increase 
            ? product.precioVenta * (1 + _percentageChange / 100) 
            : product.precioVenta * (1 - _percentageChange / 100);
        
        await _repo.updateProduct(id, Product(
          nombre: product.nombre, 
          codigo: product.codigo, 
          costo: product.costo,
          precioVenta: newPrice,
          stockActual: product.stockActual,
          stockMinimo: product.stockMinimo,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Precios actualizados en ${_selectedIds.length} productos'), 
            backgroundColor: Colors.black,
          ),
        );
        _selectedIds.clear(); 
        await _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.black),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Precios Masivo'), 
        centerTitle: true,
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          const Text('🏷️ Configurar Cambio', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<bool>(
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de cambio', 
                                    border: OutlineInputBorder(),
                                  ), 
                                  value: _increase, 
                                  items: const [
                                    DropdownMenuItem(value: true, child: Text('➕ Aumentar')), 
                                    DropdownMenuItem(value: false, child: Text('➖ Disminuir')),
                                  ], 
                                  onChanged: (v) => setState(() => _increase = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number, 
                                  decoration: const InputDecoration(
                                    labelText: 'Porcentaje (%)', 
                                    border: OutlineInputBorder(),
                                  ), 
                                  onChanged: (v) => _percentageChange = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vista previa: \$100 → \$${(100 * (_increase ? 1 + _percentageChange/100 : 1 - _percentageChange/100)).toStringAsFixed(2)}', 
                            style: TextStyle(
                              color: _increase ? Colors.green : Colors.red, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text('📦 Productos (${_selectedIds.length}/${_products.length})', 
                          style: const TextStyle(fontWeight: FontWeight.bold)), 
                      TextButton(
                        onPressed: _selectAll, 
                        child: const Text('Seleccionar todos'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16), 
                    itemCount: _products.length, 
                    itemBuilder: (ctx, i) { 
                      final p = _products[i]; 
                      final selected = _selectedIds.contains(p.id); 
                      return Card(
                        color: selected ? Colors.blue[50] : null, 
                        child: ListTile(
                          leading: Checkbox(
                            value: selected, 
                            onChanged: (_) => _toggleSelect(p.id!),
                          ), 
                          title: Text(p.nombre, 
                              style: const TextStyle(fontWeight: FontWeight.bold)), 
                          subtitle: Text('Precio: \$${p.precioVenta.toStringAsFixed(2)}'), 
                          trailing: Text(
                            '\$${(p.precioVenta * (_increase ? 1 + _percentageChange/100 : 1 - _percentageChange/100)).toStringAsFixed(2)}', 
                            style: TextStyle(
                              color: _increase ? Colors.green : Colors.red, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ); 
                    },
                  ),
                ),
                if (_selectedIds.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.all(16), 
                    decoration: BoxDecoration(
                      color: Colors.grey[200], 
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26, 
                          blurRadius: 4, 
                          offset: Offset(0, -2),
                        ),
                      ],
                    ), 
                    child: SizedBox(
                      width: double.infinity, 
                      height: 50, 
                      child: ElevatedButton.icon(
                        onPressed: _applyChanges, 
                        icon: const Icon(Icons.check_circle), 
                        label: Text(
                          'APLICAR A ${_selectedIds.length} PRODUCTOS', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, 
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
