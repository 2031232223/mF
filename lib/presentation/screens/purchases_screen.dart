import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/models/purchase_model.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/purchase_repository.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final PurchaseRepository _purchaseRepo = PurchaseRepository();
  
  List<PurchaseItem> _cart = [];
  final _searchCtrl = TextEditingController();
  String _selectedSupplier = 'Proveedor A';
  
  double get _totalCost => _cart.fold(0.0, (sum, item) => sum + (item.cost * item.quantity));

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addProduct(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((p) => p.productId == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex] = PurchaseItem(
          productId: _cart[existingIndex].productId,
          quantity: _cart[existingIndex].quantity + 1,
          cost: _cart[existingIndex].cost,
        );
      } else {
        _cart.add(PurchaseItem(
          productId: product.id,
          quantity: 1,
          cost: product.cost,
        ));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${product.name} agregado'), backgroundColor: Colors.green),
    );
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      _cart[index] = PurchaseItem(
        productId: _cart[index].productId,
        quantity: qty,
        cost: _cart[index].cost,
      );
    });
  }

  void _confirmPurchase() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos a la compra')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text('Proveedor: $_selectedSupplier\nTotal: \$$_totalCost'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(_, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final purchase = Purchase(
        totalCost: _totalCost,
        date: dateStr,
        notes: 'Compra desde $_selectedSupplier',
      );
      
      final purchaseId = await _purchaseRepo.insertPurchase(purchase);
      
      for (var item in _cart) {
        await _purchaseRepo.insertPurchaseItems([PurchaseItem(
          purchaseId: purchaseId,
          productId: item.productId,
          quantity: item.quantity,
          cost: item.cost,
        )]);
        await _purchaseRepo.processPurchase(item.productId!, item.quantity, item.cost);
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('✅ Compra Registrada'),
            content: Text('Total: \$$_totalCost\nStock actualizado con costo promedio'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _cart.clear());
                  Navigator.pop(_);
                },
                child: const Text('Finalizar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Compra'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedSupplier,
              items: ['Proveedor A', 'Proveedor B', 'Proveedor C']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSupplier = v!),
              decoration: const InputDecoration(
                labelText: 'Proveedor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: FutureBuilder<List<Product>>(
              future: _productRepo.getAllProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!
                    .where((p) => p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
                    .toList();
                
                if (products.isEmpty) {
                  return const Center(child: Text('No hay productos'));
                }
                
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (_, i) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(products[i].name[0].toUpperCase()),
                      ),
                      title: Text(products[i].name),
                      subtitle: Text('Stock: ${products[i].stock} | Costo: \$${products[i].cost}'),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Agregar'),
                        onPressed: () => _addProduct(products[i]),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Productos a Comprar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('No hay productos agregados'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text('Producto #${_cart[i].productId}'),
                            subtitle: Text('\$${_cart[i].cost} x ${_cart[i].quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () => _updateQuantity(i, _cart[i].quantity - 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () => _updateQuantity(i, _cart[i].quantity + 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _removeItem(i),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL COMPRA:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$_totalCost', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('CONFIRMAR COMPRA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _cart.isEmpty ? null : _confirmPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
