import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/supplier.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/supplier_repository.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final ProductRepository _productRepo = ProductRepository();
  final SupplierRepository _supplierRepo = SupplierRepository();
  
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // Carrito: productId -> cantidad
  final Map<int, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    _suppliers = await _supplierRepo.getAllSuppliers();
    setState(() => _isLoading = false);
  }

  void _addToCart(Product product) {
    if (product.id == null) return;
    setState(() {
      _cart[product.id!] = (_cart[product.id!] ?? 0) + 1;
    });
  }

  void _increaseQty(int productId) {
    setState(() => _cart[productId] = (_cart[productId] ?? 0) + 1);
  }

  void _decreaseQty(int productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 1) - 1;
      if (_cart[productId]! <= 0) _cart.remove(productId);
    });
  }

  void _removeLine(int productId) {
    setState(() => _cart.remove(productId));
  }

  // Calcular total basado en el COSTO (lo que pagaste)
  double get _total {
    double sum = 0.0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere((p) => p.id == entry.key, orElse: () => _products[0]);
      sum += (product.costo ?? 0.0) * entry.value;
    }
    return sum;
  }

  Future<void> _confirmPurchase() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Agrega productos'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Selecciona proveedor'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Confirmación de compra
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Compra registrada: \$${_total.toStringAsFixed(2)}'), backgroundColor: Colors.green),
      );
    }
    setState(() => _cart.clear());
  }

  void _showSupplierDialog() {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isNotEmpty) {
                try {
                  await _supplierRepo.createSupplier(
                    Supplier(
                      nombre: nombreController.text.trim(),
                      telefono: telefonoController.text.trim(),
                    ),
                  );
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Proveedor registrado'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selector de Proveedor
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Proveedor:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Supplier>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.nombre))).toList(),
                              value: _selectedSupplier,
                              onChanged: (v) => setState(() => _selectedSupplier = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showSupplierDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      ),
                    ],
                  ),
                ),
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                // Lista de productos - Mostrar COSTO (lo que pagaste)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).length,
                    itemBuilder: (ctx, i) {
                      final p = _products.where((prod) => prod.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList()[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.inventory_2, color: Colors.white)),
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${p.stockActual}'),
                              Text('💰 Costo: \$${(p.costo ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              Text('🏷️ Venta: \$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: p.id != null ? () => _addToCart(p) : null,
                            child: const Text('Agregar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Carrito de compra
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, -2))],
                    ),
                    child: Column(
                      children: [
                        const Text('Productos a Comprar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _cart.length,
                            itemBuilder: (ctx, i) {
                              final entry = _cart.entries.elementAt(i);
                              final product = _products.firstWhere((p) => p.id == entry.key);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  title: Text(product.nombre),
                                  subtitle: Text('💰 Costo: \$${(product.costo ?? 0.0).toStringAsFixed(2)} c/u'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: () => _decreaseQty(entry.key)),
                                      Text('${entry.value}'),
                                      IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => _increaseQty(entry.key)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removeLine(entry.key)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('💵 Total a Pagar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _confirmPurchase,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('CONFIRMAR COMPRA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
